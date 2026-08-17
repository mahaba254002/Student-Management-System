# Kwale High School Student Management System (SMS)

A comprehensive, robust, and scalable Student Management System designed specifically for Kwale High School. This system digitizes administrative workflows, student records, academic tracking, and staff management into a single, unified platform.

## 🚀 Features & Functionality

### 👥 User & Role Management
- **Role-Based Access Control (RBAC):** Secure access tailored for Administrators, Principals, Deputy Principals, HODs, Teachers, and Parents.
- **Secure Authentication:** JWT-based session management with bcrypt password hashing and brute-force protection.

### 🎓 Student Administration
- **Comprehensive Profiles:** Track detailed student information including personal details, medical conditions, and allergies.
- **Admission Workflow:** Seamlessly manage new admissions, capturing KCPE marks, previous schools, and entry levels.
- **Parent & Guardian Linking:** Associate students with primary caregivers and emergency contacts.

### 📚 Academic & Class Management
- **Classes & Streams:** Organize students into forms and streams (e.g., Form 1 East, Form 2 West).
- **Subject Allocation:** Manage school curriculum and subject offerings.
- **Exam Results:** Record, track, and analyze student academic performance and exam marks across different academic terms.

### 🏫 Staff & Teacher Directory
- **Staff Records:** Maintain records for both teaching and non-teaching staff.
- **Class Teacher Assignments:** Assign and track which teachers are responsible for specific classes.

### 🛏️ Boarding & Dormitory Management
- **Dormitory Tracking:** Monitor dormitory capacities and availability.
- **Bed Assignments:** Assign students to specific dorms and bed numbers, tracking active boarding statuses.

### 📢 Communication & Notices
- **System Announcements:** Post and pin notices targeted at specific audiences (e.g., Teachers only, or All Staff).

---

## 🛠️ Technology Stack

The project is built using a modern, lightweight, and high-performance stack:

**Backend:**
- **[FastAPI](https://fastapi.tiangolo.com/):** High-performance Python web framework for building APIs.
- **[Uvicorn](https://www.uvicorn.org/):** ASGI web server implementation for Python.
- **[PyJWT](https://pyjwt.readthedocs.io/) & [Passlib](https://passlib.readthedocs.io/):** For secure token generation and password hashing.

**Database:**
- **[PostgreSQL](https://www.postgresql.org/):** Robust, open-source relational database.
- **[psycopg2](https://www.psycopg.org/):** PostgreSQL database adapter for Python.

**Frontend:**
- **Vanilla HTML5 & CSS3:** Custom, responsive UI design utilizing CSS variables and modern grid/flexbox layouts.
- **Vanilla JavaScript:** Dynamic DOM manipulation and seamless asynchronous API communication using the Fetch API.

---

## 🔒 Security Architecture
- **Parameterized SQL Queries:** Strict prevention of SQL Injection across all database interactions.
- **Rate Limiting:** In-memory tracking to prevent brute-force login attempts and DDoS vectors.
- **Security Headers:** Enforced `X-Frame-Options`, `X-Content-Type-Options`, and `X-XSS-Protection` to mitigate cross-site scripting and clickjacking.
