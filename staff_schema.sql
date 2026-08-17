-- ============================================================
-- KWALE HIGH SCHOOL MANAGEMENT SYSTEM
-- EXTENDED DATABASE SCHEMA — Staff, Subjects, Users & Seed Data
-- Run this AFTER the main schema (db.sql) is already applied.
-- ============================================================

-- ============================================================
-- 14. SUBJECTS
-- ============================================================

CREATE TABLE IF NOT EXISTS subjects (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(150) NOT NULL,

    code VARCHAR(20) UNIQUE,

    category VARCHAR(50),

    is_compulsory BOOLEAN NOT NULL DEFAULT FALSE,

    description TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT subjects_category_check
        CHECK (
            category IS NULL OR
            category IN ('SCIENCES', 'HUMANITIES', 'LANGUAGES', 'MATHEMATICS', 'TECHNICAL', 'OTHER')
        )
);


-- ============================================================
-- 15. STAFF
--
-- Covers ALL employees:
--   Teaching:      PRINCIPAL, DEPUTY_PRINCIPAL, HOD, CLASS_TEACHER, SUBJECT_TEACHER
--   Non-Teaching:  ADMIN, ACCOUNTANT, SECRETARY, LIBRARIAN,
--                  COOK, CHEF, SECURITY, DRIVER, CLEANER, OTHER
-- ============================================================

CREATE TABLE IF NOT EXISTS staff (
    id BIGSERIAL PRIMARY KEY,

    staff_number VARCHAR(30) UNIQUE NOT NULL,

    first_name  VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name   VARCHAR(100) NOT NULL,

    date_of_birth DATE,

    gender VARCHAR(20) NOT NULL DEFAULT 'MALE',

    national_id VARCHAR(50) UNIQUE,

    phone VARCHAR(30) NOT NULL,
    alternative_phone VARCHAR(30),

    email VARCHAR(150),

    photo_url VARCHAR(500),

    employment_type VARCHAR(20) NOT NULL DEFAULT 'TEACHING',

    role VARCHAR(50) NOT NULL,

    department VARCHAR(100),

    qualification VARCHAR(200),

    tsc_number VARCHAR(50),

    employment_date DATE,

    contract_type VARCHAR(30) NOT NULL DEFAULT 'PERMANENT',

    salary_grade VARCHAR(20),

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    address TEXT,
    county VARCHAR(100),
    sub_county VARCHAR(100),
    postal_address VARCHAR(100),

    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(30),

    notes TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT staff_gender_check
        CHECK (gender IN ('MALE', 'FEMALE')),

    CONSTRAINT staff_employment_type_check
        CHECK (employment_type IN ('TEACHING', 'NON_TEACHING')),

    CONSTRAINT staff_role_check
        CHECK (
            role IN (
                'PRINCIPAL', 'DEPUTY_PRINCIPAL', 'HOD',
                'CLASS_TEACHER', 'SUBJECT_TEACHER',
                'ADMIN', 'ACCOUNTANT', 'SECRETARY', 'LIBRARIAN',
                'COOK', 'CHEF', 'SECURITY', 'DRIVER', 'CLEANER', 'OTHER'
            )
        ),

    CONSTRAINT staff_contract_check
        CHECK (contract_type IN ('PERMANENT', 'CONTRACT', 'INTERN', 'CASUAL')),

    CONSTRAINT staff_status_check
        CHECK (
            status IN ('ACTIVE', 'ON_LEAVE', 'SUSPENDED', 'TERMINATED', 'RETIRED')
        )
);


-- ============================================================
-- 16. STAFF SUBJECT ASSIGNMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS staff_subjects (
    id BIGSERIAL PRIMARY KEY,

    staff_id   BIGINT NOT NULL,
    subject_id BIGINT NOT NULL,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ss_staff
        FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE,

    CONSTRAINT fk_ss_subject
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,

    CONSTRAINT unique_staff_subject
        UNIQUE (staff_id, subject_id)
);


-- ============================================================
-- 17. STAFF CLASS ASSIGNMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS staff_class_assignments (
    id BIGSERIAL PRIMARY KEY,

    staff_id         BIGINT NOT NULL,
    class_id         BIGINT NOT NULL,
    subject_id       BIGINT,
    academic_year_id BIGINT NOT NULL,

    assignment_role VARCHAR(30) NOT NULL DEFAULT 'SUBJECT_TEACHER',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sca_staff
        FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE,

    CONSTRAINT fk_sca_class
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,

    CONSTRAINT fk_sca_subject
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,

    CONSTRAINT fk_sca_year
        FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,

    CONSTRAINT sca_role_check
        CHECK (assignment_role IN ('CLASS_TEACHER', 'SUBJECT_TEACHER'))
);


-- ============================================================
-- 18. HOD DEPARTMENT ASSIGNMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS hod_assignments (
    id BIGSERIAL PRIMARY KEY,

    staff_id         BIGINT NOT NULL,
    subject_id       BIGINT,
    department_name  VARCHAR(100) NOT NULL,
    academic_year_id BIGINT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_hod_staff
        FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE,

    CONSTRAINT fk_hod_subject
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,

    CONSTRAINT fk_hod_year
        FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,

    CONSTRAINT unique_hod_per_dept_year
        UNIQUE (department_name, academic_year_id)
);


-- ============================================================
-- 19. SYSTEM USERS
-- ============================================================

CREATE TABLE IF NOT EXISTS system_users (
    id BIGSERIAL PRIMARY KEY,

    username VARCHAR(100) UNIQUE NOT NULL,

    password_hash VARCHAR(255) NOT NULL,

    role VARCHAR(50) NOT NULL,

    staff_id   BIGINT,
    student_id BIGINT,
    parent_id  BIGINT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    last_login TIMESTAMP,

    must_change_password BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_su_staff
        FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE SET NULL,

    CONSTRAINT fk_su_student
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,

    CONSTRAINT fk_su_parent
        FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE SET NULL,

    CONSTRAINT system_user_role_check
        CHECK (
            role IN (
                'admin', 'principal', 'deputy_principal',
                'hod', 'teacher', 'accountant', 'parent', 'student'
            )
        )
);


-- ============================================================
-- 20. SCHOOL NOTICES / ANNOUNCEMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS notices (
    id BIGSERIAL PRIMARY KEY,

    title VARCHAR(255) NOT NULL,

    body TEXT NOT NULL,

    posted_by BIGINT,

    target_audience VARCHAR(50) NOT NULL DEFAULT 'ALL',

    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,

    expires_at DATE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notice_staff
        FOREIGN KEY (posted_by) REFERENCES staff(id) ON DELETE SET NULL,

    CONSTRAINT notice_audience_check
        CHECK (
            target_audience IN ('ALL', 'TEACHERS', 'STUDENTS', 'PARENTS', 'STAFF')
        )
);


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_staff_role       ON staff(role);
CREATE INDEX IF NOT EXISTS idx_staff_status     ON staff(status);
CREATE INDEX IF NOT EXISTS idx_staff_emp_type   ON staff(employment_type);
CREATE INDEX IF NOT EXISTS idx_staff_number     ON staff(staff_number);
CREATE INDEX IF NOT EXISTS idx_staff_subjects   ON staff_subjects(staff_id);
CREATE INDEX IF NOT EXISTS idx_sca_staff        ON staff_class_assignments(staff_id);
CREATE INDEX IF NOT EXISTS idx_sca_class        ON staff_class_assignments(class_id);
CREATE INDEX IF NOT EXISTS idx_system_users_un  ON system_users(username);
CREATE INDEX IF NOT EXISTS idx_notices_audience ON notices(target_audience);


-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_staff_updated_at ON staff;
CREATE TRIGGER update_staff_updated_at
BEFORE UPDATE ON staff
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- ============================================================

-- ============================================================
-- 19. ADMIN SEED DATA ONLY (As requested by user)
-- ============================================================

INSERT INTO staff (
    staff_number, first_name, last_name,
    gender, phone, email,
    employment_type, role, department, 
    employment_date, contract_type, status
) VALUES (
    'KHS/ADM003','Admin', 'User',
    'MALE', '0711100003','admin@kwalehigh.sc.ke',
    'NON_TEACHING','ADMIN','Administration', 
    '2015-06-01','PERMANENT','ACTIVE'
) ON CONFLICT (staff_number) DO NOTHING;


INSERT INTO system_users (username, password_hash, role, staff_id, is_active, must_change_password)
SELECT 'admin', 'admin123', 'admin', s.id, TRUE, FALSE
FROM staff s WHERE s.staff_number = 'KHS/ADM003'
ON CONFLICT (username) DO NOTHING;
