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
-- SEED DATA
-- ============================================================

-- Academic Years
INSERT INTO academic_years (year, start_date, end_date, is_current)
VALUES
    (2024, '2024-01-15', '2024-11-30', FALSE),
    (2025, '2025-01-13', '2025-11-28', TRUE)
ON CONFLICT (year) DO NOTHING;


-- Classes
INSERT INTO classes (name, level, stream, capacity)
VALUES
    ('Form 1 East',  'FORM 1', 'EAST',  45),
    ('Form 1 West',  'FORM 1', 'WEST',  45),
    ('Form 2 East',  'FORM 2', 'EAST',  45),
    ('Form 2 West',  'FORM 2', 'WEST',  45),
    ('Form 3 North', 'FORM 3', 'NORTH', 45),
    ('Form 3 South', 'FORM 3', 'SOUTH', 45),
    ('Form 4 North', 'FORM 4', 'NORTH', 45),
    ('Form 4 South', 'FORM 4', 'SOUTH', 45)
ON CONFLICT (level, stream) DO NOTHING;


-- Dormitories
INSERT INTO dormitories (name, capacity, gender)
VALUES
    ('Mombasa House',  80, 'MALE'),
    ('Nairobi House',  80, 'MALE'),
    ('Kilimanjaro',    60, 'MALE'),
    ('Maasai Block',   60, 'MALE')
ON CONFLICT (name) DO NOTHING;


-- Subjects
INSERT INTO subjects (name, code, category, is_compulsory)
VALUES
    ('Mathematics',          'MATH',   'MATHEMATICS', TRUE),
    ('English',              'ENG',    'LANGUAGES',   TRUE),
    ('Kiswahili',            'KSW',    'LANGUAGES',   TRUE),
    ('Biology',              'BIO',    'SCIENCES',    FALSE),
    ('Chemistry',            'CHEM',   'SCIENCES',    FALSE),
    ('Physics',              'PHY',    'SCIENCES',    FALSE),
    ('History & Government', 'HIST',   'HUMANITIES',  FALSE),
    ('Geography',            'GEO',    'HUMANITIES',  FALSE),
    ('Christian Religious Education', 'CRE', 'HUMANITIES', FALSE),
    ('Business Studies',     'BST',    'HUMANITIES',  FALSE),
    ('Computer Studies',     'COMP',   'TECHNICAL',   FALSE),
    ('Agriculture',          'AGRI',   'TECHNICAL',   FALSE),
    ('Home Science',         'HSC',    'TECHNICAL',   FALSE),
    ('Art & Design',         'ART',    'TECHNICAL',   FALSE),
    ('Physical Education',   'PE',     'TECHNICAL',   FALSE)
ON CONFLICT (code) DO NOTHING;


-- Previous Schools
INSERT INTO schools (name, emis_code, county, sub_county, school_level)
VALUES
    ('Kwale Primary School',     'KWL001', 'Kwale',   'Kwale',       'PRIMARY'),
    ('Shimba Hills Primary',     'KWL002', 'Kwale',   'Kinango',     'PRIMARY'),
    ('Msambweni Primary School', 'KWL003', 'Kwale',   'Msambweni',   'PRIMARY'),
    ('Ukunda Primary School',    'KWL004', 'Kwale',   'Diani',       'PRIMARY'),
    ('Kombani Primary School',   'KWL005', 'Kwale',   'Lunga Lunga', 'PRIMARY'),
    ('Lungalunga Primary',       'KWL006', 'Kwale',   'Lunga Lunga', 'PRIMARY'),
    ('Mombasa Primary School',   'MSA001', 'Mombasa', 'Mvita',       'PRIMARY'),
    ('Likoni Primary School',    'MSA002', 'Mombasa', 'Likoni',      'PRIMARY')
ON CONFLICT (emis_code) DO NOTHING;


-- Staff
INSERT INTO staff (
    staff_number, first_name, middle_name, last_name,
    date_of_birth, gender, national_id, phone, email,
    employment_type, role, department, qualification,
    tsc_number, employment_date, contract_type, salary_grade, status,
    county, sub_county
) VALUES
('KHS/ADM001','Fatuma','Aisha',   'Mwangi',  '1972-03-14','FEMALE','10234567','0722100001','principal@kwalehigh.sc.ke',
 'TEACHING','PRINCIPAL','Administration','PhD Education Management','TSC/0001001','2010-01-10','PERMANENT','P-Scale 12','ACTIVE','Kwale','Kwale'),
('KHS/ADM002','Hassan','Juma',    'Kirui',   '1975-07-22','MALE',  '20345678','0733100002','deputy@kwalehigh.sc.ke',
 'TEACHING','DEPUTY_PRINCIPAL','Administration','M.Ed Educational Administration','TSC/0001002','2012-03-01','PERMANENT','P-Scale 11','ACTIVE','Kwale','Msambweni'),
('KHS/ADM003','Salim', 'Omar',    'Abdullah','1980-11-05','MALE',  '30456789','0711100003','admin@kwalehigh.sc.ke',
 'NON_TEACHING','ADMIN','Administration','B.Com Business Administration',NULL,'2015-06-01','PERMANENT',NULL,'ACTIVE','Kwale','Kwale'),
('KHS/T001',  'Grace', 'Wanjiku', 'Otieno',  '1982-04-18','FEMALE','40567890','0722200001','grace.otieno@kwalehigh.sc.ke',
 'TEACHING','HOD','Mathematics','B.Ed Mathematics & Physics','TSC/0002001','2008-09-01','PERMANENT','T-Scale 9','ACTIVE','Kwale','Kwale'),
('KHS/T002',  'David', 'Mwangi',  'Njoroge', '1985-09-12','MALE',  '50678901','0733200002','david.njoroge@kwalehigh.sc.ke',
 'TEACHING','CLASS_TEACHER','Mathematics','B.Ed Mathematics','TSC/0002002','2013-01-15','PERMANENT','T-Scale 7','ACTIVE','Kwale','Matuga'),
('KHS/T003',  'Amina', 'Said',    'Hassan',  '1990-02-28','FEMALE','60789012','0711200003','amina.hassan@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Mathematics','B.Sc Mathematics','TSC/0002003','2017-01-10','PERMANENT','T-Scale 6','ACTIVE','Kwale','Kinango'),
('KHS/T004',  'Peter', 'Otieno',  'Mwenda',  '1983-06-10','MALE',  '70890123','0722300004','peter.mwenda@kwalehigh.sc.ke',
 'TEACHING','HOD','Sciences','B.Ed Biology & Chemistry','TSC/0003001','2009-02-01','PERMANENT','T-Scale 9','ACTIVE','Kwale','Msambweni'),
('KHS/T005',  'Joyce', 'Auma',    'Odhiambo','1988-12-03','FEMALE','80901234','0733300005','joyce.odhiambo@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Sciences','B.Sc Biology','TSC/0003002','2014-09-01','PERMANENT','T-Scale 7','ACTIVE','Kwale','Diani'),
('KHS/T006',  'Samuel','Kipchoge','Rono',    '1991-08-21','MALE',  '90012345','0711300006','samuel.rono@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Sciences','B.Sc Physics & Chemistry','TSC/0003003','2018-01-15','PERMANENT','T-Scale 6','ACTIVE','Kwale','Kwale'),
('KHS/T007',  'Mary',  'Wanjiru', 'Kamau',   '1979-01-30','FEMALE','01123456','0722400007','mary.kamau@kwalehigh.sc.ke',
 'TEACHING','HOD','Languages','B.Ed English & Literature','TSC/0004001','2006-03-01','PERMANENT','T-Scale 10','ACTIVE','Kwale','Lunga Lunga'),
('KHS/T008',  'Ali',   'Omar',    'Fadhili', '1987-05-15','MALE',  '11234567','0733400008','ali.fadhili@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Languages','B.Ed Kiswahili','TSC/0004002','2015-09-01','PERMANENT','T-Scale 7','ACTIVE','Kwale','Matuga'),
('KHS/T009',  'Rose',  'Adhiambo','Omondi',  '1984-10-08','FEMALE','21345678','0711400009','rose.omondi@kwalehigh.sc.ke',
 'TEACHING','HOD','Humanities','B.Ed History & Geography','TSC/0005001','2011-01-10','PERMANENT','T-Scale 8','ACTIVE','Kwale','Msambweni'),
('KHS/T010',  'James', 'Kiprotich','Bett',   '1993-07-19','MALE',  '31456789','0722500010','james.bett@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Humanities','B.A Geography','TSC/0005002','2019-01-14','PERMANENT','T-Scale 5','ACTIVE','Kwale','Kinango'),
('KHS/T011',  'Esther','Njoki',   'Muthoni', '1989-03-25','FEMALE','41567890','0733500011','esther.muthoni@kwalehigh.sc.ke',
 'TEACHING','CLASS_TEACHER','Humanities','B.Ed History & CRE','TSC/0005003','2016-09-01','PERMANENT','T-Scale 6','ACTIVE','Kwale','Diani'),
('KHS/T012',  'John',  'Kamande', 'Gitau',   '1994-11-11','MALE',  '51678901','0711500012','john.gitau@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Mathematics','B.Sc Mathematics & Computer Science','TSC/0002004','2020-01-13','PERMANENT','T-Scale 5','ACTIVE','Kwale','Kwale'),
('KHS/T013',  'Lilian','Chebet',  'Kiptoo',  '1986-06-04','FEMALE','61789012','0722600013','lilian.kiptoo@kwalehigh.sc.ke',
 'TEACHING','SUBJECT_TEACHER','Sciences','B.Sc Chemistry','TSC/0003004','2014-01-10','PERMANENT','T-Scale 7','ON_LEAVE','Kwale','Matuga'),
('KHS/ACC001','Amina', 'Fatuma',  'Suleiman','1981-09-17','FEMALE','71890123','0733600014','accountant@kwalehigh.sc.ke',
 'NON_TEACHING','ACCOUNTANT','Finance','B.Com Accounting & CPA-K',NULL,'2011-06-01','PERMANENT',NULL,'ACTIVE','Kwale','Kwale'),
('KHS/NT001', 'Zainab','Juma',    'Mwagandi','1985-12-20','FEMALE','81901234','0711600015','secretary@kwalehigh.sc.ke',
 'NON_TEACHING','SECRETARY','Administration','Diploma in Secretarial Studies',NULL,'2014-03-01','PERMANENT',NULL,'ACTIVE','Kwale','Msambweni'),
('KHS/NT002', 'Dennis','Mwamba',  'Kazungu', '1988-04-07','MALE',  '91012345','0722700016',NULL,
 'NON_TEACHING','LIBRARIAN','Library','Diploma in Library & Information Science',NULL,'2016-09-01','PERMANENT',NULL,'ACTIVE','Kwale','Kinango'),
('KHS/NT003', 'Mariam','Ahmed',   'Rashid',  '1980-08-13','FEMALE','02123456','0733700017',NULL,
 'NON_TEACHING','CHEF','Kitchen','Certificate in Hotel & Catering',NULL,'2012-01-10','PERMANENT',NULL,'ACTIVE','Kwale','Lunga Lunga'),
('KHS/NT004', 'Joseph','Mwangi',  'Gicheru', '1984-05-30','MALE',  '12234567','0711700018',NULL,
 'NON_TEACHING','COOK','Kitchen','Certificate in Catering',NULL,'2013-06-01','PERMANENT',NULL,'ACTIVE','Kwale','Diani'),
('KHS/NT005', 'Hadija','Omar',    'Ali',     '1991-02-14','FEMALE','22345678','0722800019',NULL,
 'NON_TEACHING','COOK','Kitchen','Certificate in Catering',NULL,'2018-01-10','CONTRACT',NULL,'ACTIVE','Kwale','Kwale'),
('KHS/NT006', 'George','Otieno',  'Ouma',    '1979-11-25','MALE',  '32456789','0733800020',NULL,
 'NON_TEACHING','SECURITY','Security','Certificate in Security Management',NULL,'2010-03-01','PERMANENT',NULL,'ACTIVE','Kwale','Matuga'),
('KHS/NT007', 'Francis','Njau',   'Mwangi',  '1982-07-09','MALE',  '42567890','0711800021',NULL,
 'NON_TEACHING','SECURITY','Security','KCSE Certificate',NULL,'2015-01-10','PERMANENT',NULL,'ACTIVE','Kwale','Msambweni'),
('KHS/NT008', 'Fatuma','Hamisi',  'Baraka',  '1990-09-03','FEMALE','52678901','0722900022',NULL,
 'NON_TEACHING','CLEANER','Maintenance','KCPE Certificate',NULL,'2017-06-01','PERMANENT',NULL,'ACTIVE','Kwale','Kinango'),
('KHS/NT009', 'Mohamed','Salim',  'Juma',    '1975-04-22','MALE',  '62789012','0733900023',NULL,
 'NON_TEACHING','DRIVER','Transport','Class BCE Driving License',NULL,'2008-09-01','PERMANENT',NULL,'ACTIVE','Kwale','Kwale')
ON CONFLICT (staff_number) DO NOTHING;


-- Staff Subjects (primary)
INSERT INTO staff_subjects (staff_id, subject_id, is_primary)
SELECT s.id, sub.id, TRUE
FROM staff s, subjects sub
WHERE (s.staff_number = 'KHS/T001' AND sub.code = 'MATH')
   OR (s.staff_number = 'KHS/T002' AND sub.code = 'MATH')
   OR (s.staff_number = 'KHS/T003' AND sub.code = 'MATH')
   OR (s.staff_number = 'KHS/T012' AND sub.code = 'MATH')
   OR (s.staff_number = 'KHS/T004' AND sub.code = 'BIO')
   OR (s.staff_number = 'KHS/T005' AND sub.code = 'BIO')
   OR (s.staff_number = 'KHS/T006' AND sub.code = 'PHY')
   OR (s.staff_number = 'KHS/T013' AND sub.code = 'CHEM')
   OR (s.staff_number = 'KHS/T007' AND sub.code = 'ENG')
   OR (s.staff_number = 'KHS/T008' AND sub.code = 'KSW')
   OR (s.staff_number = 'KHS/T009' AND sub.code = 'HIST')
   OR (s.staff_number = 'KHS/T010' AND sub.code = 'GEO')
   OR (s.staff_number = 'KHS/T011' AND sub.code = 'CRE')
ON CONFLICT (staff_id, subject_id) DO NOTHING;

-- Secondary subjects
INSERT INTO staff_subjects (staff_id, subject_id, is_primary)
SELECT s.id, sub.id, FALSE
FROM staff s, subjects sub
WHERE (s.staff_number = 'KHS/T001' AND sub.code = 'PHY')
   OR (s.staff_number = 'KHS/T002' AND sub.code = 'PHY')
   OR (s.staff_number = 'KHS/T004' AND sub.code = 'CHEM')
   OR (s.staff_number = 'KHS/T006' AND sub.code = 'CHEM')
   OR (s.staff_number = 'KHS/T012' AND sub.code = 'COMP')
   OR (s.staff_number = 'KHS/T007' AND sub.code = 'KSW')
   OR (s.staff_number = 'KHS/T009' AND sub.code = 'GEO')
ON CONFLICT (staff_id, subject_id) DO NOTHING;


-- HOD Assignments (2025)
INSERT INTO hod_assignments (staff_id, department_name, academic_year_id)
SELECT s.id, t.dept, ay.id
FROM academic_years ay,
(VALUES
    ('KHS/T001', 'Mathematics'),
    ('KHS/T004', 'Sciences'),
    ('KHS/T007', 'Languages'),
    ('KHS/T009', 'Humanities')
) AS t(staff_num, dept)
JOIN staff s ON s.staff_number = t.staff_num
WHERE ay.year = 2025
ON CONFLICT (department_name, academic_year_id) DO NOTHING;


-- Students
INSERT INTO students (
    admission_number, first_name, middle_name, last_name,
    date_of_birth, gender, birth_certificate_number, nationality, status
) VALUES
('KHS/0001/2024','Ali',     'Hassan',  'Omar',     '2009-03-12','MALE','BC001','Kenyan','ACTIVE'),
('KHS/0002/2024','Brian',   'Kamau',   'Ngugi',    '2008-11-05','MALE','BC002','Kenyan','ACTIVE'),
('KHS/0003/2024','Charles', 'Omondi',  'Otieno',   '2009-07-22','MALE','BC003','Kenyan','ACTIVE'),
('KHS/0004/2024','Daniel',  'Mwangi',  'Kariuki',  '2008-04-18','MALE','BC004','Kenyan','ACTIVE'),
('KHS/0005/2024','Edwin',   'Kipchoge','Rono',     '2009-09-30','MALE','BC005','Kenyan','ACTIVE'),
('KHS/0006/2024','Farouk',  'Juma',    'Mwamba',   '2008-01-15','MALE','BC006','Kenyan','ACTIVE'),
('KHS/0007/2024','George',  'Otieno',  'Odhiambo', '2009-06-08','MALE','BC007','Kenyan','ACTIVE'),
('KHS/0008/2024','Hassan',  'Said',    'Fadhili',  '2008-12-20','MALE','BC008','Kenyan','ACTIVE'),
('KHS/0009/2024','Isaac',   'Muriithi','Gitau',    '2009-02-14','MALE','BC009','Kenyan','ACTIVE'),
('KHS/0010/2024','James',   'Ochieng', 'Aura',     '2008-08-03','MALE','BC010','Kenyan','ACTIVE'),
('KHS/0011/2024','Kevin',   'Kimani',  'Waweru',   '2010-03-25','MALE','BC011','Kenyan','ACTIVE'),
('KHS/0012/2024','Leonard', 'Muthoni', 'Kiragu',   '2010-07-11','MALE','BC012','Kenyan','ACTIVE'),
('KHS/0013/2024','Martin',  'Adhiambo','Ojwang',   '2010-11-29','MALE','BC013','Kenyan','ACTIVE'),
('KHS/0014/2024','Nathan',  'Kazungu', 'Katana',   '2010-04-06','MALE','BC014','Kenyan','ACTIVE'),
('KHS/0015/2024','Oliver',  'Baraka',  'Charo',    '2010-09-18','MALE','BC015','Kenyan','ACTIVE'),
('KHS/0016/2025','Patrick', 'Gitonga', 'Mureithi', '2011-01-22','MALE','BC016','Kenyan','ACTIVE'),
('KHS/0017/2025','Quentin', 'Ndungu',  'Murage',   '2011-05-14','MALE','BC017','Kenyan','ACTIVE'),
('KHS/0018/2025','Robert',  'Achieng', 'Oselu',    '2011-10-07','MALE','BC018','Kenyan','ACTIVE'),
('KHS/0019/2025','Samuel',  'Ouma',    'Oginga',   '2011-03-19','MALE','BC019','Kenyan','ACTIVE'),
('KHS/0020/2025','Thomas',  'Wafula',  'Barasa',   '2011-08-31','MALE','BC020','Kenyan','ACTIVE'),
('KHS/0021/2025','Victor',  'Mutua',   'Munyao',   '2011-12-05','MALE','BC021','Kenyan','ACTIVE'),
('KHS/0022/2025','Walter',  'Kinyua',  'Mwangi',   '2011-06-23','MALE','BC022','Kenyan','ACTIVE'),
('KHS/0023/2025','Xavier',  'Abdalla', 'Hussein',  '2011-02-09','MALE','BC023','Kenyan','ACTIVE'),
('KHS/0024/2025','Yusuf',   'Hamisi',  'Salim',    '2011-07-17','MALE','BC024','Kenyan','ACTIVE'),
('KHS/0025/2025','Zackary', 'Omwami',  'Wangila',  '2011-11-28','MALE','BC025','Kenyan','ACTIVE'),
('KHS/0026/2023','Adam',    'Njoroge', 'Njogu',    '2007-04-04','MALE','BC026','Kenyan','ACTIVE'),
('KHS/0027/2023','Ben',     'Chesire', 'Kibet',    '2007-09-16','MALE','BC027','Kenyan','ACTIVE'),
('KHS/0028/2023','Collins', 'Auma',    'Odero',    '2007-01-27','MALE','BC028','Kenyan','ACTIVE'),
('KHS/0029/2022','Derek',   'Mwenda',  'Kioko',    '2006-06-12','MALE','BC029','Kenyan','ACTIVE'),
('KHS/0030/2022','Eric',    'Wanjiku', 'Gicheru',  '2006-10-08','MALE','BC030','Kenyan','ACTIVE')
ON CONFLICT (admission_number) DO NOTHING;


-- Parents
INSERT INTO parents (first_name, last_name, national_id, phone, email, county)
VALUES
('Peter',  'Mwenda',  'NID001','0700111001','peter.mwenda@email.com','Kwale'),
('Fatuma', 'Omar',    'NID002','0700111002',NULL,                    'Kwale'),
('John',   'Kariuki', 'NID003','0700111003','john.kariuki@email.com','Kwale'),
('Amina',  'Fadhili', 'NID004','0700111004',NULL,                    'Kwale'),
('Joseph', 'Rono',    'NID005','0700111005',NULL,                    'Kwale')
ON CONFLICT (national_id) DO NOTHING;


-- Student-Parent Links
INSERT INTO student_parents (student_id, parent_id, relationship, is_primary_contact)
SELECT st.id, p.id, 'FATHER', TRUE
FROM students st, parents p
WHERE st.admission_number = 'KHS/0001/2024' AND p.national_id = 'NID002'
ON CONFLICT (student_id, parent_id) DO NOTHING;

INSERT INTO student_parents (student_id, parent_id, relationship, is_primary_contact)
SELECT st.id, p.id, 'FATHER', TRUE
FROM students st, parents p
WHERE st.admission_number = 'KHS/0009/2024' AND p.national_id = 'NID001'
ON CONFLICT (student_id, parent_id) DO NOTHING;


-- Student Admissions
INSERT INTO student_admissions (
    student_id, previous_school_id, admission_date, admission_year,
    entry_level, admission_type, admission_status
)
SELECT st.id, sc.id, '2024-01-15'::date, 2024, 'FORM 1', 'REGULAR', 'CONFIRMED'
FROM students st
CROSS JOIN (SELECT id FROM schools WHERE emis_code = 'KWL001') sc
WHERE st.admission_number IN (
    'KHS/0001/2024','KHS/0002/2024','KHS/0003/2024','KHS/0004/2024','KHS/0005/2024',
    'KHS/0006/2024','KHS/0007/2024','KHS/0008/2024','KHS/0009/2024','KHS/0010/2024'
);


-- Student Enrollments 2025 — Form 4
INSERT INTO student_enrollments (student_id, academic_year_id, class_id, enrollment_status)
SELECT st.id, ay.id, c.id, 'ACTIVE'
FROM students st
CROSS JOIN academic_years ay
CROSS JOIN classes c
WHERE ay.year = 2025 AND c.name = 'Form 4 North'
  AND st.admission_number IN ('KHS/0029/2022','KHS/0030/2022')
ON CONFLICT (student_id, academic_year_id) DO NOTHING;

-- Form 3
INSERT INTO student_enrollments (student_id, academic_year_id, class_id, enrollment_status)
SELECT st.id, ay.id, c.id, 'ACTIVE'
FROM students st
CROSS JOIN academic_years ay
CROSS JOIN classes c
WHERE ay.year = 2025 AND c.name = 'Form 3 North'
  AND st.admission_number IN (
    'KHS/0026/2023','KHS/0027/2023','KHS/0028/2023',
    'KHS/0001/2024','KHS/0002/2024','KHS/0003/2024',
    'KHS/0004/2024','KHS/0005/2024'
  )
ON CONFLICT (student_id, academic_year_id) DO NOTHING;

-- Form 2
INSERT INTO student_enrollments (student_id, academic_year_id, class_id, enrollment_status)
SELECT st.id, ay.id, c.id, 'ACTIVE'
FROM students st
CROSS JOIN academic_years ay
CROSS JOIN classes c
WHERE ay.year = 2025 AND c.name = 'Form 2 East'
  AND st.admission_number IN (
    'KHS/0006/2024','KHS/0007/2024','KHS/0008/2024',
    'KHS/0009/2024','KHS/0010/2024',
    'KHS/0011/2024','KHS/0012/2024'
  )
ON CONFLICT (student_id, academic_year_id) DO NOTHING;

-- Form 1
INSERT INTO student_enrollments (student_id, academic_year_id, class_id, enrollment_status)
SELECT st.id, ay.id, c.id, 'ACTIVE'
FROM students st
CROSS JOIN academic_years ay
CROSS JOIN classes c
WHERE ay.year = 2025 AND c.name = 'Form 1 East'
  AND st.admission_number IN (
    'KHS/0016/2025','KHS/0017/2025','KHS/0018/2025',
    'KHS/0019/2025','KHS/0020/2025','KHS/0021/2025',
    'KHS/0022/2025','KHS/0023/2025','KHS/0024/2025','KHS/0025/2025'
  )
ON CONFLICT (student_id, academic_year_id) DO NOTHING;


-- Boarding Assignments
INSERT INTO student_boarding_assignments (student_id, dormitory_id, academic_year_id, bed_number, start_date, status)
SELECT st.id, d.id, ay.id,
       'B' || LPAD(ROW_NUMBER() OVER (ORDER BY st.id)::text, 3, '0'),
       CURRENT_DATE,
       'ACTIVE'
FROM students st
CROSS JOIN dormitories d
CROSS JOIN academic_years ay
WHERE ay.year = 2025 AND d.name = 'Mombasa House'
  AND st.admission_number IN (
    'KHS/0001/2024','KHS/0002/2024','KHS/0003/2024',
    'KHS/0026/2023','KHS/0027/2023','KHS/0029/2022'
  );


-- Notices
INSERT INTO notices (title, body, posted_by, target_audience, is_pinned)
SELECT n.title, n.body, s.id, n.audience, n.pinned
FROM (VALUES
    ('Term 2 Opening Date',
     'All students to report on 5th May 2025 by 10 AM. Parents to accompany Form 1 students.',
     'ALL', TRUE),
    ('National Exams Preparation',
     'Form 4 students will have extra afternoon sessions starting 12th May. Attendance is compulsory.',
     'STUDENTS', TRUE),
    ('Staff Meeting — Friday',
     'All teaching staff to attend a mandatory meeting in the staffroom at 3 PM on Friday 16th May.',
     'TEACHERS', FALSE),
    ('Fee Payment Deadline',
     'All outstanding fees to be cleared by 30th May. Contact the accounts office for fee statements.',
     'PARENTS', FALSE),
    ('School Trip — Nairobi',
     'Form 3 students have been invited for a Science fair at Nairobi. Consent forms available at the office.',
     'STUDENTS', FALSE)
) AS n(title, body, audience, pinned)
CROSS JOIN (SELECT id FROM staff WHERE staff_number = 'KHS/ADM001') s;


-- System Users
-- NOTE: password_hash here stores PLAIN TEXT for dev only.
-- Replace with bcrypt hashes before production!
INSERT INTO system_users (username, password_hash, role, staff_id)
SELECT t.username, t.plain_pw, t.role, s.id
FROM (VALUES
    ('admin',      'admin123',      'admin',            'KHS/ADM003'),
    ('principal',  'principal123',  'principal',        'KHS/ADM001'),
    ('deputy',     'deputy123',     'deputy_principal', 'KHS/ADM002'),
    ('hod',        'hod123',        'hod',              'KHS/T001'),
    ('teacher',    'teacher123',    'teacher',          'KHS/T002'),
    ('accountant', 'accountant123', 'accountant',       'KHS/ACC001')
) AS t(username, plain_pw, role, staff_num)
JOIN staff s ON s.staff_number = t.staff_num
ON CONFLICT (username) DO NOTHING;

INSERT INTO system_users (username, password_hash, role, parent_id)
SELECT 'parent', 'parent123', 'parent', p.id
FROM parents p WHERE p.national_id = 'NID001'
ON CONFLICT (username) DO NOTHING;
