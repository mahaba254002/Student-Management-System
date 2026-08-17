-- ============================================================
-- KWALE HIGH SCHOOL — Boys-Only School Corrections & Extra Seed
-- Run AFTER db.sql and staff_schema.sql
-- ============================================================

-- ── 1. Boys-only fixes ──────────────────────────────────────
UPDATE dormitories SET gender = 'MALE';
UPDATE students    SET gender = 'MALE';

-- ── 2. Ensure 4 dormitories exist ───────────────────────────
INSERT INTO dormitories (name, capacity, gender) VALUES
    ('Simba Block',   80,  'MALE'),
    ('Nguruwe Block', 80,  'MALE'),
    ('Tembo Block',   60,  'MALE'),
    ('Chui Block',    60,  'MALE')
ON CONFLICT (name) DO NOTHING;

-- ── 3. Ensure 8 classes (Form 1-4 with two streams each) ────
INSERT INTO classes (name, level, stream, capacity) VALUES
    ('Form 1 East',  '1', 'East',  45),
    ('Form 1 West',  '1', 'West',  45),
    ('Form 2 East',  '2', 'East',  45),
    ('Form 2 West',  '2', 'West',  45),
    ('Form 3 East',  '3', 'East',  45),
    ('Form 3 West',  '3', 'West',  45),
    ('Form 4 East',  '4', 'East',  45),
    ('Form 4 West',  '4', 'West',  45)
ON CONFLICT (level, stream) DO NOTHING;

-- ── 4. Ensure current academic year exists ──────────────────
INSERT INTO academic_years (year, start_date, end_date, is_current)
VALUES (2025, '2025-01-06', '2025-11-20', TRUE)
ON CONFLICT (year) DO UPDATE SET is_current = TRUE;

UPDATE academic_years SET is_current = FALSE WHERE year != 2025;

-- ── 5. Add more students (total ~120) ───────────────────────
DO $$
DECLARE
    v_ay_id INT;
    v_class_ids INT[];
    v_dorm_ids  INT[];
    v_student_id INT;
    counter INT := 0;
    first_names TEXT[] := ARRAY[
        'Brian','Kevin','Patrick','Emmanuel','Joseph','Michael','Daniel','Samuel',
        'James','Robert','Peter','John','David','Paul','George','Francis',
        'Anthony','Charles','Henry','Edward','Thomas','Victor','Dennis','Gilbert',
        'Moses','Elijah','Caleb','Joshua','Nathan','Isaac','Benjamin','Simon',
        'Philip','Andrew','Stephen','Timothy','Marcus','Lawrence','Arnold','Fredrick',
        'Oliver','Clinton','Derrick','Collins','Edwin','Raymond','Humphrey','Barnabas',
        'Adrian','Benedict','Cornelius','Dominic','Eugene','Felix','Gerald','Harold',
        'Ivan','Jerome','Kenneth','Leonard','Maurice','Norman','Oscar','Percy',
        'Quentin','Rodney','Stanley','Terrence','Ulrich','Valentine','Walter','Xavier',
        'Yusuf','Zachary','Abdi','Hassan','Omar','Ali','Said','Rashid',
        'Hamisi','Juma','Bakari','Farid','Khalid','Tariq','Nassir','Amani'
    ];
    last_names TEXT[] := ARRAY[
        'Mwangi','Ochieng','Kamau','Otieno','Njoroge','Kimani','Omondi','Kariuki',
        'Mutua','Ngugi','Wanjiru','Mugo','Njau','Muthoni','Waithaka','Gitau',
        'Kirui','Yego','Kipkoech','Rono','Cheruiyot','Koech','Bett','Sang',
        'Barasa','Wafula','Simiyu','Masinde','Khisa','Wekesa','Namwamba','Shiundu',
        'Hassan','Omar','Ali','Mwanzi','Kilifi','Mombasa','Malindi','Lamu',
        'Juma','Bakari','Hamisi','Farid','Said','Nassir','Rashid','Khalid',
        'Abubakar','Suleiman','Abdalla','Mohammed','Ibrahim','Salim','Sharif','Haji'
    ];
    adm_prefix TEXT := 'KHS';
    v_adm TEXT;
    v_first TEXT;
    v_last  TEXT;
    v_dob   DATE;
    v_class INT;
    v_dorm  INT;
    existing_count INT;
BEGIN
    -- Get current academic year
    SELECT id INTO v_ay_id FROM academic_years WHERE is_current = TRUE LIMIT 1;

    -- Get class IDs
    SELECT ARRAY_AGG(id ORDER BY level, stream) INTO v_class_ids FROM classes WHERE level IN ('1', '2', '3', '4') LIMIT 8;

    -- Get dorm IDs
    SELECT ARRAY_AGG(id) INTO v_dorm_ids FROM dormitories LIMIT 4;

    -- Count existing students
    SELECT COUNT(*) INTO existing_count FROM students;

    FOR counter IN (existing_count + 1)..120 LOOP
        v_first := first_names[1 + (counter % array_length(first_names, 1))];
        v_last  := last_names[1 + (counter % array_length(last_names, 1))];
        v_adm   := adm_prefix || '/2025/' || LPAD(counter::TEXT, 4, '0');
        v_dob   := DATE '2007-01-01' + (((counter * 37) % 2190) || ' days')::INTERVAL;
        v_class := v_class_ids[1 + ((counter - 1) % array_length(v_class_ids, 1))];
        v_dorm  := v_dorm_ids[1 + ((counter - 1) % array_length(v_dorm_ids, 1))];

        -- Skip if admission number exists
        CONTINUE WHEN EXISTS (SELECT 1 FROM students WHERE admission_number = v_adm);

        INSERT INTO students (admission_number, first_name, last_name, date_of_birth, gender, status, nationality)
        VALUES (v_adm, v_first, v_last, v_dob, 'MALE', 'ACTIVE', 'Kenyan')
        RETURNING id INTO v_student_id;

        -- Enroll student in a class
        INSERT INTO student_enrollments (student_id, class_id, academic_year_id, enrollment_date, enrollment_status)
        VALUES (v_student_id, v_class, v_ay_id, CURRENT_DATE, 'ENROLLED')
        ON CONFLICT (student_id, academic_year_id) DO NOTHING;

        -- Assign 70% of students to dorms (boarders)
        IF counter % 10 < 7 THEN
            INSERT INTO student_boarding_assignments (student_id, dormitory_id, academic_year_id, bed_number, start_date, status)
            VALUES (v_student_id, v_dorm, v_ay_id, counter::TEXT, CURRENT_DATE, 'ACTIVE')
        END IF;

    END LOOP;
END;
$$;

-- ── 6. Assign class teachers to classes ─────────────────────
DO $$
DECLARE
    v_staff_ids INT[];
    v_class_ids INT[];
    v_ay_id INT;
    i INT;
BEGIN
    SELECT id INTO v_ay_id FROM academic_years WHERE is_current = TRUE LIMIT 1;
    
    SELECT ARRAY_AGG(id ORDER BY id) INTO v_staff_ids
    FROM staff WHERE employment_type = 'TEACHING' AND status = 'ACTIVE' LIMIT 8;

    SELECT ARRAY_AGG(id ORDER BY level, stream) INTO v_class_ids FROM classes LIMIT 8;

    IF v_staff_ids IS NOT NULL AND v_class_ids IS NOT NULL THEN
        FOR i IN 1..LEAST(array_length(v_staff_ids,1), array_length(v_class_ids,1)) LOOP
            INSERT INTO staff_class_assignments (staff_id, class_id, academic_year_id, assignment_role)
            VALUES (v_staff_ids[i], v_class_ids[i], v_ay_id, 'CLASS_TEACHER');
        END LOOP;
    END IF;
END;
$$;

-- ── 7. Add fee structure entries for fees pages ──────────────
CREATE TABLE IF NOT EXISTS fee_structure (
    id              SERIAL PRIMARY KEY,
    academic_year_id INT REFERENCES academic_years(id),
    class_level     INT NOT NULL,
    fee_type        TEXT NOT NULL,  -- 'TUITION','BOARDING','ACTIVITY','EXAM','DEVELOPMENT'
    amount          NUMERIC(10,2) NOT NULL,
    term            INT DEFAULT 1,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fee_payments (
    id              SERIAL PRIMARY KEY,
    student_id      INT REFERENCES students(id),
    academic_year_id INT REFERENCES academic_years(id),
    amount          NUMERIC(10,2) NOT NULL,
    fee_type        TEXT NOT NULL,
    term            INT DEFAULT 1,
    payment_date    DATE DEFAULT CURRENT_DATE,
    payment_method  TEXT DEFAULT 'MPESA',  -- 'MPESA','BANK','CASH'
    reference_no    TEXT,
    received_by     INT REFERENCES staff(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Fee structure for 2025
INSERT INTO fee_structure (academic_year_id, class_level, fee_type, amount, term)
SELECT ay.id, cl, ft, amt, 1
FROM academic_years ay,
(VALUES
    (1, 'TUITION',     15000),
    (1, 'BOARDING',    12000),
    (1, 'ACTIVITY',     2000),
    (1, 'EXAM',         1500),
    (1, 'DEVELOPMENT',  3000),
    (2, 'TUITION',     15000),
    (2, 'BOARDING',    12000),
    (2, 'ACTIVITY',     2000),
    (2, 'EXAM',         1500),
    (2, 'DEVELOPMENT',  3000),
    (3, 'TUITION',     16000),
    (3, 'BOARDING',    12000),
    (3, 'ACTIVITY',     2000),
    (3, 'EXAM',         2000),
    (3, 'DEVELOPMENT',  3000),
    (4, 'TUITION',     16000),
    (4, 'BOARDING',    12000),
    (4, 'ACTIVITY',     2000),
    (4, 'EXAM',         5000),
    (4, 'DEVELOPMENT',  3000)
) AS t(cl, ft, amt)
WHERE ay.is_current = TRUE;

-- Sample fee payments (60% of students paid)
INSERT INTO fee_payments (student_id, academic_year_id, amount, fee_type, term, payment_method, reference_no)
SELECT
    s.id,
    ay.id,
    33500,
    'FULL',
    1,
    CASE (ROW_NUMBER() OVER ()) % 3
        WHEN 0 THEN 'MPESA'
        WHEN 1 THEN 'BANK'
        ELSE 'CASH'
    END,
    'REF' || LPAD((ROW_NUMBER() OVER ())::TEXT, 6, '0')
FROM students s, academic_years ay
WHERE ay.is_current = TRUE
  AND s.status = 'ACTIVE'
  AND s.id % 10 < 6;  -- 60% paid

-- ── 8. Exams and exam results ────────────────────────────────
CREATE TABLE IF NOT EXISTS exams (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    academic_year_id INT REFERENCES academic_years(id),
    term            INT DEFAULT 1,
    exam_type       TEXT DEFAULT 'TERM_END',  -- 'CAT','MID_TERM','TERM_END','MOCK','KCSE'
    start_date      DATE,
    end_date        DATE,
    status          TEXT DEFAULT 'SCHEDULED',  -- 'SCHEDULED','ONGOING','COMPLETED'
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exam_results (
    id          SERIAL PRIMARY KEY,
    exam_id     INT REFERENCES exams(id),
    student_id  INT REFERENCES students(id),
    subject_id  INT REFERENCES subjects(id),
    class_id    INT REFERENCES classes(id),
    score       NUMERIC(5,2),
    grade       TEXT,
    remarks     TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(exam_id, student_id, subject_id)
);

INSERT INTO exams (name, academic_year_id, term, exam_type, start_date, end_date, status)
SELECT
    e.name, ay.id, 1, e.etype, e.sdate::DATE, e.edate::DATE, e.status
FROM academic_years ay,
(VALUES
    ('Form 1 CAT 1',         'CAT',      '2025-02-03', '2025-02-04', 'COMPLETED'),
    ('Form 2 CAT 1',         'CAT',      '2025-02-03', '2025-02-04', 'COMPLETED'),
    ('Form 3 CAT 1',         'CAT',      '2025-02-03', '2025-02-04', 'COMPLETED'),
    ('Form 4 Mock 1',        'MOCK',     '2025-02-10', '2025-02-14', 'COMPLETED'),
    ('Mid-Term Exam 2025',   'MID_TERM', '2025-02-17', '2025-02-21', 'COMPLETED'),
    ('Term 1 End Exam 2025', 'TERM_END', '2025-03-24', '2025-04-01', 'SCHEDULED')
) AS e(name, etype, sdate, edate, status)
WHERE ay.is_current = TRUE;

-- ── 9. Attendance table ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance (
    id          SERIAL PRIMARY KEY,
    student_id  INT REFERENCES students(id),
    class_id    INT REFERENCES classes(id),
    date        DATE NOT NULL,
    status      TEXT DEFAULT 'PRESENT', -- 'PRESENT','ABSENT','LATE','EXCUSED'
    recorded_by INT REFERENCES staff(id),
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, date)
);

-- Add today's attendance for active students (90% present)
INSERT INTO attendance (student_id, class_id, date, status)
SELECT
    se.student_id,
    se.class_id,
    CURRENT_DATE,
    CASE WHEN se.student_id % 10 < 9 THEN 'PRESENT' ELSE 'ABSENT' END
FROM student_enrollments se
JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = TRUE
JOIN students s ON s.id = se.student_id AND s.status = 'ACTIVE'
ON CONFLICT (student_id, date) DO NOTHING;

-- ── 10. Notices update ───────────────────────────────────────
DELETE FROM notices WHERE id > 0;  -- Clear and re-seed

INSERT INTO notices (title, body, target_audience, is_pinned, posted_by)
SELECT
    n.title, n.body, n.audience::character varying, n.pinned, s.id
FROM
(VALUES
    ('Term 1 2025 Fee Deadline',
     'All students must clear Term 1 fees by 28th February 2025. Parents who have not paid are urged to do so immediately to avoid their wards being sent home.',
     'PARENTS', TRUE),
    ('Mid-Term Exam Timetable Released',
     'The mid-term examination timetable for all forms has been uploaded. Students should collect hard copies from the deputy principal office.',
     'STUDENTS', TRUE),
    ('Staff Meeting — Monday 17th Feb',
     'All teaching and non-teaching staff are required to attend the monthly staff meeting on Monday 17th February at 4:00 PM in the staff room.',
     'TEACHERS', FALSE),
    ('Games & Sports Day — March 7th',
     'The annual inter-house sports day will be held on 7th March 2025. All students are encouraged to participate. Houses: Kilimanjaro, Mara, Rift, Coast.',
     'ALL', FALSE),
    ('KCSE Registration',
     'Form 4 students must submit their KCSE registration documents by 15th March 2025. Missing documents will result in disqualification.',
     'STUDENTS', TRUE),
    ('New Library Hours',
     'The school library is now open from 6:00 AM to 9:00 PM Monday to Saturday. Students are encouraged to make full use of this resource.',
     'ALL', FALSE),
    ('KNEC Circular — Exam Regulations',
     'Teachers and students are reminded that use of mobile phones during examinations is strictly prohibited and will result in automatic disqualification.',
     'ALL', FALSE),
    ('Parent-Teacher Meeting',
     'The Parent-Teacher Association (PTA) meeting is scheduled for Saturday 22nd February 2025 at 10:00 AM. All parents are strongly encouraged to attend.',
     'PARENTS', FALSE)
) AS n(title, body, audience, pinned)
CROSS JOIN (SELECT id FROM staff WHERE role = 'PRINCIPAL' OR role = 'DEPUTY_PRINCIPAL' LIMIT 1) s;

-- Final summary
SELECT 'Students' AS entity, COUNT(*) AS count FROM students
UNION ALL
SELECT 'Staff', COUNT(*) FROM staff
UNION ALL
SELECT 'Classes', COUNT(*) FROM classes
UNION ALL
SELECT 'Dormitories', COUNT(*) FROM dormitories
UNION ALL
SELECT 'Subjects', COUNT(*) FROM subjects
UNION ALL
SELECT 'Enrollments', COUNT(*) FROM student_enrollments se JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = TRUE
UNION ALL
SELECT 'Boarders', COUNT(*) FROM student_boarding_assignments sba JOIN academic_years ay ON ay.id = sba.academic_year_id AND ay.is_current = TRUE AND sba.status = 'ACTIVE'
UNION ALL
SELECT 'Fee Payments', COUNT(*) FROM fee_payments
UNION ALL
SELECT 'Exams', COUNT(*) FROM exams
UNION ALL
SELECT 'Notices', COUNT(*) FROM notices;



----dorms

-- ============================================================
-- SEED DATA: DORMITORIES
-- Kwale High School Management System
-- ============================================================

INSERT INTO dormitories (name, capacity, gender) VALUES
('Shimba House', 120, 'MALE'),
('Mwamba House', 100, 'MALE'),('Kaya House', 120, 'MALE'),
('Diani House', 100, 'MALE'),('Kifaru House', 80, 'MALE'),
('Tembo House', 80, 'MALE'),('Simba House', 100, 'MALE'),
('Chui House', 80, 'MALE')
ON CONFLICT (name) DO NOTHING;