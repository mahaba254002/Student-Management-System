"""
FastAPI Backend — Kwale High School SMS
Fully restructured to match the real PostgreSQL schema.
Run: uvicorn main:app --reload --port 8001
"""

from fastapi import FastAPI, HTTPException, Query, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime, timedelta
from dotenv import load_dotenv
import jwt
from passlib.context import CryptContext

load_dotenv()

# ── JWT Config ─────────────────────────────────────────────────
JWT_SECRET  = os.getenv("JWT_SECRET", "khs-super-secret-2025-change-in-production")
JWT_ALGO    = "HS256"
JWT_EXPIRY_HOURS = 8

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

app = FastAPI(title="Kwale High School SMS API", version="2.0")

# ── Security Middleware ─────────────────────────────────────────
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response

# In-memory login rate limiter: username/IP -> list of attempt timestamps
LOGIN_ATTEMPTS: Dict[str, List[datetime]] = {}
MAX_FAILED_ATTEMPTS = 5
LOCKOUT_MINUTES = 10

def check_login_rate_limit(key: str):
    now = datetime.utcnow()
    attempts = LOGIN_ATTEMPTS.get(key, [])
    # Filter attempts within lockout window
    recent = [t for t in attempts if now - t < timedelta(minutes=LOCKOUT_MINUTES)]
    LOGIN_ATTEMPTS[key] = recent
    if len(recent) >= MAX_FAILED_ATTEMPTS:
        raise HTTPException(
            status_code=429, 
            detail=f"Too many failed login attempts. Account temporarily locked for {LOCKOUT_MINUTES} minutes."
        )

def record_failed_attempt(key: str):
    attempts = LOGIN_ATTEMPTS.get(key, [])
    attempts.append(datetime.utcnow())
    LOGIN_ATTEMPTS[key] = attempts

def clear_login_attempts(key: str):
    if key in LOGIN_ATTEMPTS:
        del LOGIN_ATTEMPTS[key]

# ── CORS — restrict to localhost for production change to your domain
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:8001,http://127.0.0.1:8001,http://localhost:3000").split(",")
# If ALLOWED_ORIGINS contains "*", we allow all
if "*" in ALLOWED_ORIGINS:
    ALLOWED_ORIGINS = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["*"],
)

# ── DB Config ────────────────────────────────────────────────────
DATABASE_URL = os.getenv("DATABASE_URL")

DB_CONFIG = {
    "host":     os.getenv("DB_HOST",     "localhost"),
    "database": os.getenv("DB_NAME",     "kwale_high_school"),
    "user":     os.getenv("DB_USER",     "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
    "port":     os.getenv("DB_PORT",     "5432"),
}

def get_db():
    """Create and return a database connection."""
    try:
        if DATABASE_URL:
            # For Render or Heroku PostgreSQL deployments
            conn = psycopg2.connect(DATABASE_URL)
        else:
            # Fallback for local development
            conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB connection failed: {e}")


# ════════════════════════════════════════════════════════════════
# HEALTH & INITIALIZATION
# ════════════════════════════════════════════════════════════════

@app.get("/api/health")
def health():
    return {"status": "ok", "service": "Kwale High School SMS", "version": "2.0"}

@app.get("/api/init-db")
def init_db_endpoint():
    """Temporary endpoint to initialize the database on Render Free Tier."""
    try:
        conn = get_db()
        cur = conn.cursor()
        
        sql_files = ["schema_generated.sql", "seed_extra.sql"]
        results = []
        
        for file in sql_files:
            if os.path.exists(file):
                with open(file, 'r', encoding='utf-8') as f:
                    sql = f.read()
                    cur.execute(sql)
                conn.commit()
                results.append(f"Successfully executed {file}")
            else:
                results.append(f"Warning: {file} not found")
                
        conn.close()
        return {"status": "success", "message": "Database initialized successfully!", "details": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to initialize database: {e}")



# ════════════════════════════════════════════════════════════════
# AUTH
# ════════════════════════════════════════════════════════════════

class LoginRequest(BaseModel):
    username: str
    password: str


def create_jwt(payload: dict) -> str:
    data = payload.copy()
    data["exp"] = datetime.utcnow() + timedelta(hours=JWT_EXPIRY_HOURS)
    return jwt.encode(data, JWT_SECRET, algorithm=JWT_ALGO)


def verify_jwt(authorization: Optional[str] = Header(None)) -> dict:
    """FastAPI dependency: validates Bearer JWT."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ", 1)[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Session expired, please login again")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.post("/api/auth/login")
def login(req: LoginRequest):
    """Authenticate user, verify bcrypt password, return JWT with brute force rate limiting."""
    rate_limit_key = req.username.lower()
    check_login_rate_limit(rate_limit_key)

    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT u.id, u.username, u.role, u.is_active, u.password_hash,
                   u.staff_id, u.student_id, u.parent_id,
                   s.first_name, s.last_name, s.staff_number,
                   s.department, s.role as staff_role, s.id as s_id
            FROM system_users u
            LEFT JOIN staff s ON s.id = u.staff_id
            WHERE u.username = %s
        """, (req.username.lower(),))
        user = cur.fetchone()

        if not user:
            record_failed_attempt(rate_limit_key)
            raise HTTPException(status_code=401, detail="Invalid username or password")
        if not user["is_active"]:
            raise HTTPException(status_code=403, detail="Account is inactive")

        # Verify password with bcrypt
        if not pwd_context.verify(req.password, user["password_hash"]):
            record_failed_attempt(rate_limit_key)
            raise HTTPException(status_code=401, detail="Invalid username or password")

        # Successful login -> clear failed attempts
        clear_login_attempts(rate_limit_key)

        # Build display name
        if user["first_name"]:
            name = f"{user['first_name']} {user['last_name']}"
        else:
            name = user["username"].title()

        parts = name.split()
        avatar = (parts[0][0] + parts[-1][0]).upper() if len(parts) >= 2 else name[:2].upper()

        user_data = {
            "id":          user["id"],
            "username":    user["username"],
            "role":        user["role"],
            "name":        name,
            "avatar":      avatar,
            "staffId":     user["staff_id"],
            "staffNumber": user["staff_number"],
            "department":  user["department"],
            "staffRole":   user["staff_role"],
        }

        token = create_jwt({"sub": user["username"], "role": user["role"],
                            "staff_id": user["staff_id"]})

        return {"success": True, "token": token, "user": user_data}
    finally:
        conn.close()


@app.get("/api/users")
def get_users():
    """List system users."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT u.id, u.username, u.role, u.is_active, u.created_at,
                   u.staff_id, u.student_id, u.parent_id,
                   s.first_name || ' ' || s.last_name AS linked_name,
                   s.staff_number, s.department
            FROM system_users u
            LEFT JOIN staff s ON s.id = u.staff_id
            ORDER BY u.role, u.username
        """)
        return cur.fetchall()
    finally:
        conn.close()


class UserCreate(BaseModel):
    username: str
    password: str
    role: str
    # For teacher accounts — link to existing staff
    staff_id: Optional[int] = None
    # For parent accounts — link via student admission_number
    student_admission_number: Optional[str] = None
    parent_first_name: Optional[str] = None
    parent_last_name: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[str] = None
    parent_relationship: Optional[str] = "FATHER"

@app.post("/api/users", status_code=201)
def create_user(data: UserCreate):
    """Create a new system user (teacher login or parent account)."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Check username uniqueness
        cur.execute("SELECT id FROM system_users WHERE username = %s", (data.username.lower(),))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail=f"Username '{data.username}' is already taken")

        hashed = pwd_context.hash(data.password)
        parent_id = None

        # If creating a parent, create/find the parent record first
        if data.role == "parent":
            if not data.student_admission_number:
                raise HTTPException(status_code=400, detail="Student admission number is required for parent accounts")
            if not data.parent_first_name or not data.parent_last_name:
                raise HTTPException(status_code=400, detail="Parent first and last name required")

            # Find the student
            cur.execute("SELECT id FROM students WHERE admission_number = %s", (data.student_admission_number,))
            student = cur.fetchone()
            if not student:
                raise HTTPException(status_code=404, detail=f"No student found with admission number: {data.student_admission_number}")

            # Create parent record
            cur.execute("""
                INSERT INTO parents (first_name, last_name, phone, email)
                VALUES (%s, %s, %s, %s) RETURNING id
            """, (data.parent_first_name, data.parent_last_name, data.parent_phone, data.parent_email))
            parent_id = cur.fetchone()["id"]

            # Link student to parent
            cur.execute("""
                INSERT INTO student_parents (student_id, parent_id, relationship, is_primary_contact, is_emergency_contact)
                VALUES (%s, %s, %s, TRUE, TRUE)
                ON CONFLICT DO NOTHING
            """, (student["id"], parent_id, data.parent_relationship))

        # Create the system user
        cur.execute("""
            INSERT INTO system_users (username, password_hash, role, is_active, staff_id, parent_id)
            VALUES (%s, %s, %s, TRUE, %s, %s)
            RETURNING id, username, role, is_active, created_at
        """, (data.username.lower(), hashed, data.role, data.staff_id, parent_id))
        result = dict(cur.fetchone())
        conn.commit()
        return result
    finally:
        conn.close()


@app.patch("/api/users/{user_id}/toggle")
def toggle_user_status(user_id: int):
    """Activate or deactivate a user account."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            UPDATE system_users SET is_active = NOT is_active
            WHERE id = %s RETURNING id, username, is_active
        """, (user_id,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="User not found")
        conn.commit()
        return r
    finally:
        conn.close()


@app.patch("/api/users/{user_id}/reset-password")
def reset_user_password(user_id: int, body: dict):
    """Reset a user's password (admin action)."""
    new_password = body.get("password", "")
    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        hashed = pwd_context.hash(new_password)
        cur.execute("UPDATE system_users SET password_hash = %s WHERE id = %s RETURNING id", (hashed, user_id))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="User not found")
        conn.commit()
        return {"success": True, "message": "Password reset successfully"}
    finally:
        conn.close()



# ════════════════════════════════════════════════════════════════
# DASHBOARD STATS
# ════════════════════════════════════════════════════════════════

@app.get("/api/stats/dashboard")
def dashboard_stats():
    """Top-level stats for the admin dashboard."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("SELECT COUNT(*) as total FROM students WHERE status = 'ACTIVE'")
        students = cur.fetchone()["total"]

        cur.execute("SELECT COUNT(*) as total FROM staff WHERE employment_type = 'TEACHING' AND status = 'ACTIVE'")
        teachers = cur.fetchone()["total"]

        cur.execute("SELECT COUNT(*) as total FROM staff WHERE employment_type = 'TEACHING' AND status = 'ON_LEAVE'")
        on_leave = cur.fetchone()["total"]

        cur.execute("SELECT COUNT(*) as total FROM staff WHERE employment_type = 'NON_TEACHING' AND status = 'ACTIVE'")
        non_teaching = cur.fetchone()["total"]

        cur.execute("SELECT COUNT(*) as total FROM classes")
        classes = cur.fetchone()["total"]

        cur.execute("SELECT COUNT(*) as total FROM dormitories")
        dorms = cur.fetchone()["total"]

        cur.execute("""
            SELECT COUNT(*) as total FROM student_boarding_assignments
            WHERE status = 'ACTIVE'
        """)
        boarders = cur.fetchone()["total"]

        return {
            "students":    students,
            "teachers":    teachers,
            "teachersOnLeave": on_leave,
            "nonTeachingStaff": non_teaching,
            "classes":     classes,
            "dormitories": dorms,
            "boarders":    boarders,
        }
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# STUDENTS
# ════════════════════════════════════════════════════════════════

@app.get("/api/students")
def get_students(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500),
    search: Optional[str] = None,
    status: Optional[str] = None,
    class_id: Optional[int] = None,
    year: Optional[int] = None,
):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Join with current enrollment to get class name
        query = """
            SELECT
                st.id,
                st.admission_number,
                st.first_name,
                st.middle_name,
                st.last_name,
                st.date_of_birth,
                st.gender,
                st.status,
                st.photo_url,
                st.created_at,
                c.name AS class_name,
                c.level AS class_level,
                ay.year AS academic_year
            FROM students st
            LEFT JOIN student_enrollments se
                ON se.student_id = st.id
            LEFT JOIN classes c ON c.id = se.class_id
            LEFT JOIN academic_years ay ON ay.id = se.academic_year_id
                AND (ay.is_current = TRUE OR %s IS NOT NULL)
            WHERE 1=1
        """
        params: list = [year]

        if search:
            query += """ AND (
                st.first_name ILIKE %s OR st.last_name ILIKE %s OR
                st.middle_name ILIKE %s OR st.admission_number ILIKE %s
            )"""
            like = f"%{search}%"
            params += [like, like, like, like]

        if status:
            query += " AND st.status = %s"
            params.append(status.upper())

        if class_id:
            query += " AND se.class_id = %s"
            params.append(class_id)

        if year:
            query += " AND ay.year = %s"
            params.append(year)
        else:
            query += " AND (ay.is_current = TRUE OR ay.id IS NULL)"

        query += " ORDER BY st.last_name, st.first_name LIMIT %s OFFSET %s"
        params += [limit, skip]

        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/students/count")
def count_students(status: Optional[str] = None):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        if status:
            cur.execute("SELECT COUNT(*) as count FROM students WHERE status = %s", (status.upper(),))
        else:
            cur.execute("SELECT COUNT(*) as count FROM students")
        return cur.fetchone()
    finally:
        conn.close()


@app.get("/api/students/{student_id}")
def get_student(student_id: int):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("""
            SELECT
                st.*,
                c.name AS class_name,
                c.level AS class_level,
                ay.year AS academic_year,
                d.name AS dormitory_name,
                sba.bed_number,
                sc.name AS previous_school
            FROM students st
            LEFT JOIN student_enrollments se ON se.student_id = st.id
            LEFT JOIN classes c ON c.id = se.class_id
            LEFT JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = TRUE
            LEFT JOIN student_boarding_assignments sba
                ON sba.student_id = st.id AND sba.status = 'ACTIVE'
            LEFT JOIN dormitories d ON d.id = sba.dormitory_id
            LEFT JOIN student_admissions sa ON sa.student_id = st.id
            LEFT JOIN schools sc ON sc.id = sa.previous_school_id
            WHERE st.id = %s
        """, (student_id,))

        student = cur.fetchone()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")

        # Parents
        cur.execute("""
            SELECT p.*, sp.relationship, sp.is_primary_contact, sp.is_emergency_contact
            FROM parents p
            JOIN student_parents sp ON sp.parent_id = p.id
            WHERE sp.student_id = %s
        """, (student_id,))
        student = dict(student)
        student["parents"] = cur.fetchall()

        return student
    finally:
        conn.close()


class StudentAdmissionCreate(BaseModel):
    first_name: str
    last_name: str
    middle_name: Optional[str] = None
    date_of_birth: str
    gender: str = "MALE"
    admission_number: Optional[str] = None
    birth_certificate_number: Optional[str] = None
    nationality: str = "Kenyan"
    class_id: Optional[int] = None
    dormitory_id: Optional[int] = None
    bed_number: Optional[str] = None
    previous_school_id: Optional[int] = None
    entry_level: Optional[str] = "FORM 1"
    admission_type: str = "REGULAR"
    parent_first_name: Optional[str] = None
    parent_last_name: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[str] = None
    parent_national_id: Optional[str] = None
    parent_relationship: str = "FATHER"
    emergency_name: Optional[str] = None
    emergency_phone: Optional[str] = None
    emergency_relationship: Optional[str] = "GUARDIAN"

@app.post("/api/students", status_code=201)
def admit_student(data: StudentAdmissionCreate):
    """Full admission workflow: student record, enrollment, boarding, previous school, parent, and emergency contact."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # 1. Generate admission number if not provided
        adm_no = data.admission_number
        if not adm_no:
            cur.execute("SELECT COUNT(*) as count FROM students")
            cnt = cur.fetchone()["count"] + 1
            adm_no = f"KHS/2025/{cnt:04d}"

        # 2. Insert Student
        cur.execute("""
            INSERT INTO students (
                admission_number, first_name, middle_name, last_name,
                date_of_birth, gender, birth_certificate_number, nationality, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'ACTIVE')
            RETURNING id, admission_number, first_name, last_name
        """, (
            adm_no, data.first_name, data.middle_name, data.last_name,
            data.date_of_birth, data.gender, data.birth_certificate_number, data.nationality
        ))
        student = cur.fetchone()
        student_id = student["id"]

        # Get active academic year
        cur.execute("SELECT id FROM academic_years WHERE is_current = TRUE LIMIT 1")
        ay = cur.fetchone()
        ay_id = ay["id"] if ay else 2

        # 3. Class Enrollment
        if data.class_id:
            cur.execute("""
                INSERT INTO student_enrollments (student_id, academic_year_id, class_id, enrollment_date, enrollment_status)
                VALUES (%s, %s, %s, CURRENT_DATE, 'ACTIVE')
            """, (student_id, ay_id, data.class_id))

        # 4. Dormitory Boarding Assignment
        if data.dormitory_id:
            cur.execute("""
                INSERT INTO student_boarding_assignments (student_id, dormitory_id, academic_year_id, bed_number, start_date, status)
                VALUES (%s, %s, %s, %s, CURRENT_DATE, 'ACTIVE')
            """, (student_id, data.dormitory_id, ay_id, data.bed_number or "Auto"))

        # 5. Previous School Admission Record
        if data.previous_school_id:
            cur.execute("""
                INSERT INTO student_admissions (
                    student_id, previous_school_id, admission_date, admission_year,
                    entry_level, admission_type, admission_status
                ) VALUES (%s, %s, CURRENT_DATE, 2025, %s, %s, 'CONFIRMED')
            """, (student_id, data.previous_school_id, data.entry_level, data.admission_type))

        # 6. Parent Details
        if data.parent_first_name and data.parent_last_name:
            cur.execute("""
                INSERT INTO parents (first_name, last_name, phone, email, national_id)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
            """, (data.parent_first_name, data.parent_last_name, data.parent_phone, data.parent_email, data.parent_national_id))
            parent_id = cur.fetchone()["id"]

            cur.execute("""
                INSERT INTO student_parents (student_id, parent_id, relationship, is_primary_contact, is_emergency_contact)
                VALUES (%s, %s, %s, TRUE, TRUE)
            """, (student_id, parent_id, data.parent_relationship))

        # 7. Emergency Contact
        if data.emergency_name and data.emergency_phone:
            cur.execute("""
                INSERT INTO emergency_contacts (student_id, full_name, phone, relationship, priority)
                VALUES (%s, %s, %s, %s, 1)
            """, (student_id, data.emergency_name, data.emergency_phone, data.emergency_relationship))

        conn.commit()
        return student
    finally:
        conn.close()



# ════════════════════════════════════════════════════════════════
# STAFF
# ════════════════════════════════════════════════════════════════

@app.get("/api/staff")
def get_staff(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    search: Optional[str] = None,
    employment_type: Optional[str] = None,
    role: Optional[str] = None,
    status: Optional[str] = None,
    department: Optional[str] = None,
):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        query = """
            SELECT
                s.id, s.staff_number, s.first_name, s.middle_name, s.last_name,
                s.gender, s.phone, s.email, s.employment_type, s.role,
                s.department, s.qualification, s.tsc_number, s.contract_type,
                s.salary_grade, s.status, s.employment_date, s.county,
                s.photo_url,
                ARRAY_AGG(DISTINCT sub.name) FILTER (WHERE sub.name IS NOT NULL) AS subjects
            FROM staff s
            LEFT JOIN staff_subjects ss ON ss.staff_id = s.id
            LEFT JOIN subjects sub ON sub.id = ss.subject_id
            WHERE 1=1
        """
        params = []

        if search:
            query += """ AND (
                s.first_name ILIKE %s OR s.last_name ILIKE %s OR
                s.middle_name ILIKE %s OR s.staff_number ILIKE %s OR
                s.email ILIKE %s
            )"""
            like = f"%{search}%"
            params += [like, like, like, like, like]

        if employment_type:
            query += " AND s.employment_type = %s"
            params.append(employment_type.upper())

        if role:
            query += " AND s.role = %s"
            params.append(role.upper())

        if status:
            query += " AND s.status = %s"
            params.append(status.upper())

        if department:
            query += " AND s.department ILIKE %s"
            params.append(f"%{department}%")

        query += " GROUP BY s.id ORDER BY s.last_name, s.first_name LIMIT %s OFFSET %s"
        params += [limit, skip]

        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/staff/{staff_id}")
def get_staff_member(staff_id: int):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("""
            SELECT s.*,
                   ARRAY_AGG(DISTINCT sub.name) FILTER (WHERE sub.name IS NOT NULL) AS subjects,
                   ARRAY_AGG(DISTINCT c.name)   FILTER (WHERE c.name IS NOT NULL)   AS classes
            FROM staff s
            LEFT JOIN staff_subjects ss ON ss.staff_id = s.id
            LEFT JOIN subjects sub ON sub.id = ss.subject_id
            LEFT JOIN staff_class_assignments sca ON sca.staff_id = s.id
            LEFT JOIN classes c ON c.id = sca.class_id
            WHERE s.id = %s
            GROUP BY s.id
        """, (staff_id,))

        member = cur.fetchone()
        if not member:
            raise HTTPException(status_code=404, detail="Staff member not found")
        return member
    finally:
        conn.close()


@app.get("/api/staff/stats/summary")
def staff_stats():
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("""
            SELECT
                COUNT(*) FILTER (WHERE employment_type = 'TEACHING' AND status = 'ACTIVE') AS active_teachers,
                COUNT(*) FILTER (WHERE employment_type = 'TEACHING' AND status = 'ON_LEAVE') AS on_leave,
                COUNT(*) FILTER (WHERE employment_type = 'NON_TEACHING' AND status = 'ACTIVE') AS non_teaching,
                COUNT(*) FILTER (WHERE role = 'HOD') AS hod_count,
                COUNT(*) FILTER (WHERE role = 'CLASS_TEACHER') AS class_teachers,
                COUNT(*) FILTER (WHERE role IN ('COOK','CHEF')) AS kitchen_staff,
                COUNT(*) FILTER (WHERE role = 'SECURITY') AS security_count,
                COUNT(*) AS total
            FROM staff
        """)
        return cur.fetchone()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# CLASSES
# ════════════════════════════════════════════════════════════════

@app.get("/api/classes")
def get_classes(year: Optional[int] = None):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT
                c.id, c.name, c.level, c.stream, c.capacity,
                COUNT(DISTINCT se.student_id) AS enrolled,
                s.first_name || ' ' || s.last_name AS class_teacher,
                s.id AS class_teacher_id
            FROM classes c
            LEFT JOIN student_enrollments se ON se.class_id = c.id
            LEFT JOIN academic_years ay ON ay.id = se.academic_year_id
                AND (ay.is_current = TRUE OR %s IS NOT NULL)
            LEFT JOIN staff_class_assignments sca
                ON sca.class_id = c.id AND sca.assignment_role = 'CLASS_TEACHER'
            LEFT JOIN staff s ON s.id = sca.staff_id
            GROUP BY c.id, c.name, c.level, c.stream, c.capacity, s.first_name, s.last_name, s.id
            ORDER BY c.level, c.stream
        """, (year,))
        return cur.fetchall()
    finally:
        conn.close()


class AssignTeacherRequest(BaseModel):
    class_id: int
    staff_id: int

@app.post("/api/classes/assign-teacher")
def assign_class_teacher(data: AssignTeacherRequest):
    """Assign or update a teacher as class teacher for a class."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # Remove any existing class teacher for this class
        cur.execute("""
            DELETE FROM staff_class_assignments 
            WHERE class_id = %s AND assignment_role = 'CLASS_TEACHER'
        """, (data.class_id,))

        # Assign new class teacher
        cur.execute("""
            INSERT INTO staff_class_assignments (staff_id, class_id, academic_year_id, assignment_role)
            VALUES (%s, %s, (SELECT id FROM academic_years WHERE is_current = TRUE LIMIT 1), 'CLASS_TEACHER')
            RETURNING *
        """, (data.staff_id, data.class_id))
        res = cur.fetchone()
        conn.commit()
        return {"success": True, "assignment": res}
    finally:
        conn.close()



# ════════════════════════════════════════════════════════════════
# SUBJECTS
# ════════════════════════════════════════════════════════════════

@app.get("/api/subjects")
def get_subjects():
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT sub.*,
                   COUNT(DISTINCT ss.staff_id) AS teacher_count
            FROM subjects sub
            LEFT JOIN staff_subjects ss ON ss.subject_id = sub.id
            GROUP BY sub.id
            ORDER BY sub.category, sub.name
        """)
        return cur.fetchall()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# DORMITORIES
# ════════════════════════════════════════════════════════════════

@app.get("/api/dormitories")
def get_dormitories():
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT
                d.id, d.name, d.capacity, d.gender,
                COUNT(sba.id) FILTER (WHERE sba.status = 'ACTIVE') AS occupied,
                d.capacity - COUNT(sba.id) FILTER (WHERE sba.status = 'ACTIVE') AS available
            FROM dormitories d
            LEFT JOIN student_boarding_assignments sba ON sba.dormitory_id = d.id
            LEFT JOIN academic_years ay ON ay.id = sba.academic_year_id AND ay.is_current = TRUE
            GROUP BY d.id
            ORDER BY d.name
        """)
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/dormitories/{dorm_id}/students")
def get_dorm_students(dorm_id: int):
    """Get all students currently assigned to a specific dormitory."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT st.id, st.first_name, st.middle_name, st.last_name,
                   st.admission_number, st.status,
                   sba.bed_number, sba.status AS boarding_status,
                   c.name AS class_name, c.level, c.stream
            FROM student_boarding_assignments sba
            JOIN students st ON st.id = sba.student_id
            LEFT JOIN student_enrollments se ON se.student_id = st.id
            LEFT JOIN academic_years ayen ON ayen.id = se.academic_year_id AND ayen.is_current = TRUE
            LEFT JOIN classes c ON c.id = se.class_id
            WHERE sba.dormitory_id = %s AND sba.status = 'ACTIVE'
            ORDER BY c.level, c.stream, st.last_name, st.first_name
        """, (dorm_id,))
        return cur.fetchall()
    finally:
        conn.close()



# ════════════════════════════════════════════════════════════════
# ACADEMIC YEARS
# ════════════════════════════════════════════════════════════════

@app.get("/api/academic-years")
def get_academic_years():
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM academic_years ORDER BY year DESC")
        return cur.fetchall()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# NOTICES
# ════════════════════════════════════════════════════════════════

@app.get("/api/notices")
def get_notices(audience: Optional[str] = None, limit: int = 10):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        query = """
            SELECT n.*,
                   s.first_name || ' ' || s.last_name AS posted_by_name,
                   s.role AS posted_by_role
            FROM notices n
            LEFT JOIN staff s ON s.id = n.posted_by
            WHERE 1=1
        """
        params = []
        if audience:
            query += " AND (n.target_audience = %s OR n.target_audience = 'ALL')"
            params.append(audience.upper())
        query += " ORDER BY n.is_pinned DESC, n.created_at DESC LIMIT %s"
        params.append(limit)
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# SCHOOLS (Previous schools)
# ════════════════════════════════════════════════════════════════

@app.get("/api/schools")
def get_schools(search: Optional[str] = None):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        query = "SELECT * FROM schools WHERE 1=1"
        params = []
        if search:
            query += " AND (name ILIKE %s OR county ILIKE %s)"
            like = f"%{search}%"
            params += [like, like]
        query += " ORDER BY name"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# EXAMS & QUERIES
# ════════════════════════════════════════════════════════════════

@app.get("/api/exams")
def get_exams():
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM exams ORDER BY id DESC")
        return cur.fetchall()
    finally:
        conn.close()

# /api/custom_query removed — was a SQL injection vulnerability

# Duplicate staff/{id} endpoint removed — primary one is at line ~373


# Duplicate students/{id} endpoint removed — primary is at line ~246

# ════════════════════════════════════════════════════════════════
# ATTENDANCE
# ════════════════════════════════════════════════════════════════

@app.get("/api/attendance")
def get_attendance(class_id: Optional[int] = None, date: Optional[str] = None):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        query = """
            SELECT a.*, s.first_name, s.last_name, s.admission_number, c.name as class_name
            FROM attendance a
            JOIN students s ON s.id = a.student_id
            JOIN classes c ON c.id = a.class_id
            WHERE 1=1
        """
        params = []
        if class_id:
            query += " AND a.class_id = %s"
            params.append(class_id)
        if date:
            query += " AND a.date = %s"
            params.append(date)
        
        query += " ORDER BY a.date DESC, c.level, c.stream, s.last_name LIMIT 100"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()

# ════════════════════════════════════════════════════════════════
# FINANCE
# ════════════════════════════════════════════════════════════════

@app.get("/api/finance/fees")
def get_fees(student_id: Optional[int] = None, limit: int = 50):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        query = """
            SELECT p.*, s.first_name, s.last_name, s.admission_number
            FROM fee_payments p
            JOIN students s ON s.id = p.student_id
            WHERE 1=1
        """
        params = []
        if student_id:
            query += " AND p.student_id = %s"
            params.append(student_id)
            
        query += " ORDER BY p.payment_date DESC, p.id DESC LIMIT %s"
        params.append(limit)
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# CREATE ACADEMIC YEAR
# ════════════════════════════════════════════════════════════════

class AcademicYearCreate(BaseModel):
    year: int
    start_date: str
    end_date: str
    is_current: bool = False

@app.post("/api/academic-years", status_code=201)
def create_academic_year(data: AcademicYearCreate):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        if data.is_current:
            cur.execute("UPDATE academic_years SET is_current = FALSE")
        cur.execute("""
            INSERT INTO academic_years (year, start_date, end_date, is_current)
            VALUES (%s, %s, %s, %s)
            RETURNING *
        """, (data.year, data.start_date, data.end_date, data.is_current))
        result = cur.fetchone()
        conn.commit()
        return result
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# CREATE STAFF
# ════════════════════════════════════════════════════════════════

class StaffCreate(BaseModel):
    first_name: str
    last_name: str
    middle_name: Optional[str] = None
    gender: str = "MALE"
    phone: Optional[str] = None
    email: Optional[str] = None
    national_id: Optional[str] = None
    employment_type: str = "TEACHING"
    role: str = "SUBJECT_TEACHER"
    department: Optional[str] = None
    qualification: Optional[str] = None
    tsc_number: Optional[str] = None
    employment_date: Optional[str] = None
    contract_type: str = "PERMANENT"
    salary_grade: Optional[str] = None
    county: Optional[str] = None

@app.post("/api/staff", status_code=201)
def create_staff(data: StaffCreate):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # Auto-generate staff number
        prefix = "T" if data.employment_type == "TEACHING" else "S"
        cur.execute(f"SELECT COUNT(*) as cnt FROM staff WHERE employment_type = %s", (data.employment_type,))
        count = cur.fetchone()["cnt"]
        staff_number = f"{prefix}-{count + 100:03d}"

        cur.execute("""
            INSERT INTO staff (
                staff_number, first_name, middle_name, last_name, gender,
                phone, email, national_id, employment_type, role, department,
                qualification, tsc_number, employment_date, contract_type,
                salary_grade, county, status
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'ACTIVE')
            RETURNING *
        """, (
            staff_number, data.first_name, data.middle_name, data.last_name,
            data.gender, data.phone, data.email, data.national_id,
            data.employment_type, data.role, data.department,
            data.qualification, data.tsc_number, data.employment_date,
            data.contract_type, data.salary_grade, data.county
        ))
        result = cur.fetchone()
        conn.commit()
        return result
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# TEACHER-SPECIFIC ENDPOINTS
# ════════════════════════════════════════════════════════════════

@app.get("/api/teacher/{staff_id}/classes")
def get_teacher_classes(staff_id: int):
    """Get all classes assigned to a teacher."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT DISTINCT c.id, c.name, c.level, c.stream, c.capacity,
                   sca.assignment_role,
                   COUNT(DISTINCT se.student_id) as enrolled
            FROM classes c
            JOIN staff_class_assignments sca ON sca.class_id = c.id
            LEFT JOIN student_enrollments se ON se.class_id = c.id
            LEFT JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = TRUE
            WHERE sca.staff_id = %s
            GROUP BY c.id, c.name, c.level, c.stream, c.capacity, sca.assignment_role
            ORDER BY c.level, c.stream
        """, (staff_id,))
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/teacher/{staff_id}/students")
def get_teacher_students(staff_id: int):
    """Get all students taught by this teacher (via class assignments)."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT st.id, st.first_name, st.last_name, st.middle_name,
                   st.admission_number, st.status, st.gender,
                   c.name as class_name, c.id as class_id, c.level as class_level, c.stream as class_stream,
                   d.name as dorm_name
            FROM students st
            JOIN student_enrollments se ON se.student_id = st.id
            JOIN classes c ON c.id = se.class_id
            JOIN staff_class_assignments sca ON sca.class_id = c.id
            LEFT JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = TRUE
            LEFT JOIN student_boarding_assignments sba ON sba.student_id = st.id AND sba.status = 'ACTIVE'
            LEFT JOIN dormitories d ON d.id = sba.dormitory_id
            WHERE sca.staff_id = %s AND st.status = 'ACTIVE'
            ORDER BY c.level, c.stream, st.last_name, st.first_name
        """, (staff_id,))
        return cur.fetchall()
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# MARKS
# ════════════════════════════════════════════════════════════════

class MarkEntry(BaseModel):
    student_id: int
    exam_id: int
    subject_id: int
    score: float
    grade: Optional[str] = None
    remarks: Optional[str] = None
    class_id: Optional[int] = None

class BulkMarkEntry(BaseModel):
    marks: List[MarkEntry]

@app.get("/api/marks")
def get_marks(
    exam_id: Optional[int] = None,
    class_id: Optional[int] = None,
    student_id: Optional[int] = None,
):
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        query = """
            SELECT m.*, 
                   st.first_name, st.last_name, st.admission_number,
                   sub.name as subject_name,
                   e.name as exam_name,
                   c.name as class_name
            FROM exam_results m
            JOIN students st ON st.id = m.student_id
            JOIN subjects sub ON sub.id = m.subject_id
            JOIN exams e ON e.id = m.exam_id
            LEFT JOIN classes c ON c.id = m.class_id
            WHERE 1=1
        """
        params = []
        if exam_id:
            query += " AND m.exam_id = %s"; params.append(exam_id)
        if student_id:
            query += " AND m.student_id = %s"; params.append(student_id)
        if class_id:
            query += " AND (m.class_id = %s OR m.student_id IN (SELECT student_id FROM student_enrollments WHERE class_id = %s))"
            params.extend([class_id, class_id])
        query += " ORDER BY st.last_name, sub.name"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/marks", status_code=201)
def submit_marks(data: BulkMarkEntry):
    """Submit or update marks for students in exam_results."""
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        for m in data.marks:
            # Calculate grade automatically if not provided
            grade = m.grade
            if not grade:
                if m.score >= 80: grade = 'A'
                elif m.score >= 75: grade = 'A-'
                elif m.score >= 70: grade = 'B+'
                elif m.score >= 65: grade = 'B'
                elif m.score >= 60: grade = 'B-'
                elif m.score >= 55: grade = 'C+'
                elif m.score >= 50: grade = 'C'
                elif m.score >= 45: grade = 'C-'
                elif m.score >= 40: grade = 'D+'
                elif m.score >= 35: grade = 'D'
                elif m.score >= 30: grade = 'D-'
                else: grade = 'E'

            cur.execute("""
                INSERT INTO exam_results (exam_id, student_id, subject_id, class_id, score, grade, remarks)
                VALUES (%s, %s, %s, 
                        COALESCE(%s, (SELECT class_id FROM student_enrollments WHERE student_id = %s LIMIT 1)),
                        %s, %s, %s)
                ON CONFLICT (exam_id, student_id, subject_id)
                DO UPDATE SET score = EXCLUDED.score, grade = EXCLUDED.grade, remarks = EXCLUDED.remarks, class_id = EXCLUDED.class_id
            """, (m.exam_id, m.student_id, m.subject_id, m.class_id, m.student_id, m.score, grade, m.remarks))
        conn.commit()
        return {"success": True, "saved": len(data.marks)}
    finally:
        conn.close()


# ════════════════════════════════════════════════════════════════
# Serve static files (HTML/CSS/JS)
# ════════════════════════════════════════════════════════════════

app.mount("/pages", StaticFiles(directory="pages"), name="pages")
app.mount("/", StaticFiles(directory=".", html=True), name="root")

@app.get("/")
def serve_login():
    return FileResponse("index.html")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
