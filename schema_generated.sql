-- GENERATED SCHEMA FROM LOCAL DATABASE

CREATE TABLE IF NOT EXISTS academic_years (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    year integer NOT NULL UNIQUE,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_current boolean NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS classes (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    level VARCHAR(255) NOT NULL,
    stream VARCHAR(255),
    capacity integer,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (level, stream)
);

CREATE TABLE IF NOT EXISTS dormitories (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    capacity integer NOT NULL,
    gender VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS subjects (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(255) UNIQUE,
    category VARCHAR(255),
    is_compulsory boolean NOT NULL,
    description text,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS schools (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    emis_code VARCHAR(255) UNIQUE,
    county VARCHAR(255),
    sub_county VARCHAR(255),
    school_level VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    username VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active boolean NOT NULL,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parents (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    last_name VARCHAR(255) NOT NULL,
    national_id VARCHAR(255) UNIQUE,
    phone VARCHAR(255) NOT NULL,
    alternative_phone VARCHAR(255),
    email VARCHAR(255),
    occupation VARCHAR(255),
    address text,
    county VARCHAR(255),
    sub_county VARCHAR(255),
    postal_address VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    staff_number VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    last_name VARCHAR(255) NOT NULL,
    date_of_birth date,
    gender VARCHAR(255) NOT NULL,
    national_id VARCHAR(255) UNIQUE,
    phone VARCHAR(255) NOT NULL,
    alternative_phone VARCHAR(255),
    email VARCHAR(255),
    photo_url VARCHAR(255),
    employment_type VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    department VARCHAR(255),
    qualification VARCHAR(255),
    tsc_number VARCHAR(255),
    employment_date date,
    contract_type VARCHAR(255) NOT NULL,
    salary_grade VARCHAR(255),
    status VARCHAR(255) NOT NULL,
    address text,
    county VARCHAR(255),
    sub_county VARCHAR(255),
    postal_address VARCHAR(255),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(255),
    notes text,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS students (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    admission_number VARCHAR(255) UNIQUE,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    last_name VARCHAR(255) NOT NULL,
    date_of_birth date NOT NULL,
    gender VARCHAR(255) NOT NULL,
    birth_certificate_number VARCHAR(255) UNIQUE,
    nationality VARCHAR(255) NOT NULL DEFAULT 'Kenyan',
    photo_url VARCHAR(255),
    status VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exams (
    id SERIAL NOT NULL PRIMARY KEY,
    name text NOT NULL,
    academic_year_id integer REFERENCES academic_years(id),
    term integer,
    exam_type text,
    start_date date,
    end_date date,
    status text,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exam_results (
    id SERIAL NOT NULL PRIMARY KEY,
    exam_id integer REFERENCES exams(id),
    student_id integer REFERENCES students(id),
    subject_id integer REFERENCES subjects(id),
    class_id integer REFERENCES classes(id),
    score numeric,
    grade VARCHAR(255),
    remarks text,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (exam_id, student_id, subject_id)
);

CREATE TABLE IF NOT EXISTS fee_structure (
    id SERIAL NOT NULL PRIMARY KEY,
    academic_year_id integer REFERENCES academic_years(id),
    class_level integer NOT NULL,
    fee_type text NOT NULL,
    amount numeric NOT NULL,
    term integer,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fee_payments (
    id SERIAL NOT NULL PRIMARY KEY,
    student_id integer REFERENCES students(id),
    academic_year_id integer REFERENCES academic_years(id),
    amount numeric NOT NULL,
    fee_type text NOT NULL,
    term integer,
    payment_date date,
    payment_method text,
    reference_no text,
    received_by integer REFERENCES staff(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL NOT NULL PRIMARY KEY,
    student_id integer UNIQUE,
    class_id integer REFERENCES classes(id),
    date date NOT NULL UNIQUE,
    status text,
    recorded_by integer REFERENCES staff(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES students(id),
    full_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(255) NOT NULL,
    phone VARCHAR(255) NOT NULL,
    alternative_phone VARCHAR(255),
    address text,
    priority integer NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hod_assignments (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    staff_id bigint NOT NULL REFERENCES staff(id),
    subject_id bigint REFERENCES subjects(id),
    department_name VARCHAR(255) NOT NULL UNIQUE,
    academic_year_id bigint NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notices (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body text NOT NULL,
    posted_by bigint REFERENCES staff(id),
    target_audience VARCHAR(255) NOT NULL,
    is_pinned boolean NOT NULL,
    expires_at date,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff_class_assignments (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    staff_id bigint NOT NULL REFERENCES staff(id),
    class_id bigint NOT NULL REFERENCES classes(id),
    subject_id bigint REFERENCES subjects(id),
    academic_year_id bigint NOT NULL REFERENCES academic_years(id),
    assignment_role VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff_subjects (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    staff_id bigint NOT NULL REFERENCES staff(id),
    subject_id bigint NOT NULL REFERENCES subjects(id),
    is_primary boolean NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (staff_id, subject_id)
);

CREATE TABLE IF NOT EXISTS student_admission_requests (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    requested_by bigint NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    last_name VARCHAR(255) NOT NULL,
    date_of_birth date,
    gender VARCHAR(255),
    requested_class_id bigint REFERENCES classes(id),
    reason text,
    status VARCHAR(255) NOT NULL,
    reviewed_by bigint,
    reviewed_at TIMESTAMP,
    rejection_reason text,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_admissions (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES students(id),
    previous_school_id bigint REFERENCES schools(id),
    admission_date date NOT NULL,
    admission_year integer NOT NULL,
    entry_level VARCHAR(255),
    admission_type VARCHAR(255),
    admission_letter_number VARCHAR(255),
    admission_status VARCHAR(255) NOT NULL,
    approved_by bigint,
    approved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_boarding_assignments (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES students(id),
    dormitory_id bigint NOT NULL REFERENCES dormitories(id),
    academic_year_id bigint NOT NULL REFERENCES academic_years(id),
    bed_number VARCHAR(255),
    start_date date NOT NULL,
    end_date date,
    status VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_documents (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES students(id),
    document_type VARCHAR(255) NOT NULL,
    document_number VARCHAR(255),
    file_url VARCHAR(255) NOT NULL,
    issue_date date,
    is_verified boolean NOT NULL,
    verified_by bigint,
    verified_at TIMESTAMP,
    uploaded_at TIMESTAMP NOT NULL,
    notes text
);

CREATE TABLE IF NOT EXISTS student_enrollments (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES students(id),
    academic_year_id bigint NOT NULL REFERENCES academic_years(id),
    class_id bigint NOT NULL REFERENCES classes(id),
    enrollment_date date NOT NULL,
    enrollment_status VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, academic_year_id)
);

CREATE TABLE IF NOT EXISTS student_parents (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES students(id),
    parent_id bigint NOT NULL REFERENCES parents(id),
    relationship VARCHAR(255) NOT NULL,
    is_primary_contact boolean NOT NULL,
    is_emergency_contact boolean NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, parent_id)
);

CREATE TABLE IF NOT EXISTS system_users (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    staff_id bigint REFERENCES staff(id),
    student_id bigint REFERENCES students(id),
    parent_id bigint REFERENCES parents(id),
    is_active boolean NOT NULL,
    last_login TIMESTAMP,
    must_change_password boolean NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

