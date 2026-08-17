import csv

csv_data = """table_name,column_name,data_type,is_nullable,constraint_type
academic_years,id,bigint,NO,PRIMARY KEY
academic_years,year,integer,NO,UNIQUE
academic_years,start_date,date,NO,
academic_years,end_date,date,NO,
academic_years,is_current,boolean,NO,
academic_years,created_at,timestamp without time zone,NO,
attendance,id,integer,NO,PRIMARY KEY
attendance,student_id,integer,YES,UNIQUE
attendance,class_id,integer,YES,FOREIGN KEY
attendance,date,date,NO,UNIQUE
attendance,status,text,YES,
attendance,recorded_by,integer,YES,FOREIGN KEY
attendance,created_at,timestamp with time zone,YES,
classes,id,bigint,NO,PRIMARY KEY
classes,name,character varying,NO,
classes,level,character varying,NO,UNIQUE
classes,stream,character varying,YES,UNIQUE
classes,capacity,integer,YES,
classes,created_at,timestamp without time zone,NO,
dormitories,id,bigint,NO,PRIMARY KEY
dormitories,name,character varying,NO,UNIQUE
dormitories,capacity,integer,NO,
dormitories,gender,character varying,YES,
dormitories,created_at,timestamp without time zone,NO,
emergency_contacts,id,bigint,NO,PRIMARY KEY
emergency_contacts,student_id,bigint,NO,FOREIGN KEY
emergency_contacts,full_name,character varying,NO,
emergency_contacts,relationship,character varying,NO,
emergency_contacts,phone,character varying,NO,
emergency_contacts,alternative_phone,character varying,YES,
emergency_contacts,address,text,YES,
emergency_contacts,priority,integer,NO,
emergency_contacts,created_at,timestamp without time zone,NO,
exam_results,id,integer,NO,PRIMARY KEY
exam_results,exam_id,integer,YES,UNIQUE
exam_results,student_id,integer,YES,UNIQUE
exam_results,subject_id,integer,YES,UNIQUE
exam_results,class_id,integer,YES,FOREIGN KEY
exam_results,score,numeric,YES,
exam_results,grade,text,YES,
exam_results,remarks,text,YES,
exam_results,created_at,timestamp with time zone,YES,
exams,id,integer,NO,PRIMARY KEY
exams,name,text,NO,
exams,academic_year_id,integer,YES,FOREIGN KEY
exams,term,integer,YES,
exams,exam_type,text,YES,
exams,start_date,date,YES,
exams,end_date,date,YES,
exams,status,text,YES,
exams,created_at,timestamp with time zone,YES,
fee_payments,id,integer,NO,PRIMARY KEY
fee_payments,student_id,integer,YES,FOREIGN KEY
fee_payments,academic_year_id,integer,YES,FOREIGN KEY
fee_payments,amount,numeric,NO,
fee_payments,fee_type,text,NO,
fee_payments,term,integer,YES,
fee_payments,payment_date,date,YES,
fee_payments,payment_method,text,YES,
fee_payments,reference_no,text,YES,
fee_payments,received_by,integer,YES,FOREIGN KEY
fee_payments,created_at,timestamp with time zone,YES,
fee_structure,id,integer,NO,PRIMARY KEY
fee_structure,academic_year_id,integer,YES,FOREIGN KEY
fee_structure,class_level,integer,NO,
fee_structure,fee_type,text,NO,
fee_structure,amount,numeric,NO,
fee_structure,term,integer,YES,
fee_structure,created_at,timestamp with time zone,YES,
hod_assignments,id,bigint,NO,PRIMARY KEY
hod_assignments,staff_id,bigint,NO,FOREIGN KEY
hod_assignments,subject_id,bigint,YES,FOREIGN KEY
hod_assignments,department_name,character varying,NO,UNIQUE
hod_assignments,academic_year_id,bigint,NO,UNIQUE
hod_assignments,created_at,timestamp without time zone,NO,
notices,id,bigint,NO,PRIMARY KEY
notices,title,character varying,NO,
notices,body,text,NO,
notices,posted_by,bigint,YES,FOREIGN KEY
notices,target_audience,character varying,NO,
notices,is_pinned,boolean,NO,
notices,expires_at,date,YES,
notices,created_at,timestamp without time zone,NO,
parents,id,bigint,NO,PRIMARY KEY
parents,first_name,character varying,NO,
parents,middle_name,character varying,YES,
parents,last_name,character varying,NO,
parents,national_id,character varying,YES,UNIQUE
parents,phone,character varying,NO,
parents,alternative_phone,character varying,YES,
parents,email,character varying,YES,
parents,occupation,character varying,YES,
parents,address,text,YES,
parents,county,character varying,YES,
parents,sub_county,character varying,YES,
parents,postal_address,character varying,YES,
parents,created_at,timestamp without time zone,NO,
parents,updated_at,timestamp without time zone,NO,
schools,id,bigint,NO,PRIMARY KEY
schools,name,character varying,NO,
schools,emis_code,character varying,YES,UNIQUE
schools,county,character varying,YES,
schools,sub_county,character varying,YES,
schools,school_level,character varying,NO,
schools,created_at,timestamp without time zone,NO,
staff,id,bigint,NO,PRIMARY KEY
staff,staff_number,character varying,NO,UNIQUE
staff,first_name,character varying,NO,
staff,middle_name,character varying,YES,
staff,last_name,character varying,NO,
staff,date_of_birth,date,YES,
staff,gender,character varying,NO,
staff,national_id,character varying,YES,UNIQUE
staff,phone,character varying,NO,
staff,alternative_phone,character varying,YES,
staff,email,character varying,YES,
staff,photo_url,character varying,YES,
staff,employment_type,character varying,NO,
staff,role,character varying,NO,
staff,department,character varying,YES,
staff,qualification,character varying,YES,
staff,tsc_number,character varying,YES,
staff,employment_date,date,YES,
staff,contract_type,character varying,NO,
staff,salary_grade,character varying,YES,
staff,status,character varying,NO,
staff,address,text,YES,
staff,county,character varying,YES,
staff,sub_county,character varying,YES,
staff,postal_address,character varying,YES,
staff,emergency_contact_name,character varying,YES,
staff,emergency_contact_phone,character varying,YES,
staff,notes,text,YES,
staff,created_at,timestamp without time zone,NO,
staff,updated_at,timestamp without time zone,NO,
staff_class_assignments,id,bigint,NO,PRIMARY KEY
staff_class_assignments,staff_id,bigint,NO,FOREIGN KEY
staff_class_assignments,class_id,bigint,NO,FOREIGN KEY
staff_class_assignments,subject_id,bigint,YES,FOREIGN KEY
staff_class_assignments,academic_year_id,bigint,NO,FOREIGN KEY
staff_class_assignments,assignment_role,character varying,NO,
staff_class_assignments,created_at,timestamp without time zone,NO,
staff_subjects,id,bigint,NO,PRIMARY KEY
staff_subjects,staff_id,bigint,NO,UNIQUE
staff_subjects,subject_id,bigint,NO,UNIQUE
staff_subjects,is_primary,boolean,NO,
staff_subjects,created_at,timestamp without time zone,NO,
student_admission_requests,id,bigint,NO,PRIMARY KEY
student_admission_requests,requested_by,bigint,NO,
student_admission_requests,first_name,character varying,NO,
student_admission_requests,middle_name,character varying,YES,
student_admission_requests,last_name,character varying,NO,
student_admission_requests,date_of_birth,date,YES,
student_admission_requests,gender,character varying,YES,
student_admission_requests,requested_class_id,bigint,YES,FOREIGN KEY
student_admission_requests,reason,text,YES,
student_admission_requests,status,character varying,NO,
student_admission_requests,reviewed_by,bigint,YES,
student_admission_requests,reviewed_at,timestamp without time zone,YES,
student_admission_requests,rejection_reason,text,YES,
student_admission_requests,created_at,timestamp without time zone,NO,
student_admission_requests,updated_at,timestamp without time zone,NO,
student_admissions,id,bigint,NO,PRIMARY KEY
student_admissions,student_id,bigint,NO,FOREIGN KEY
student_admissions,previous_school_id,bigint,YES,FOREIGN KEY
student_admissions,admission_date,date,NO,
student_admissions,admission_year,integer,NO,
student_admissions,entry_level,character varying,YES,
student_admissions,admission_type,character varying,YES,
student_admissions,admission_letter_number,character varying,YES,
student_admissions,admission_status,character varying,NO,
student_admissions,approved_by,bigint,YES,
student_admissions,approved_at,timestamp without time zone,YES,
student_admissions,created_at,timestamp without time zone,NO,
student_admissions,updated_at,timestamp without time zone,NO,
student_boarding_assignments,id,bigint,NO,PRIMARY KEY
student_boarding_assignments,student_id,bigint,NO,FOREIGN KEY
student_boarding_assignments,dormitory_id,bigint,NO,FOREIGN KEY
student_boarding_assignments,academic_year_id,bigint,NO,FOREIGN KEY
student_boarding_assignments,bed_number,character varying,YES,
student_boarding_assignments,start_date,date,NO,
student_boarding_assignments,end_date,date,YES,
student_boarding_assignments,status,character varying,NO,
student_boarding_assignments,created_at,timestamp without time zone,NO,
student_documents,id,bigint,NO,PRIMARY KEY
student_documents,student_id,bigint,NO,FOREIGN KEY
student_documents,document_type,character varying,NO,
student_documents,document_number,character varying,YES,
student_documents,file_url,character varying,NO,
student_documents,issue_date,date,YES,
student_documents,is_verified,boolean,NO,
student_documents,verified_by,bigint,YES,
student_documents,verified_at,timestamp without time zone,YES,
student_documents,uploaded_at,timestamp without time zone,NO,
student_documents,notes,text,YES,
student_enrollments,id,bigint,NO,PRIMARY KEY
student_enrollments,student_id,bigint,NO,UNIQUE
student_enrollments,academic_year_id,bigint,NO,UNIQUE
student_enrollments,class_id,bigint,NO,FOREIGN KEY
student_enrollments,enrollment_date,date,NO,
student_enrollments,enrollment_status,character varying,NO,
student_enrollments,created_at,timestamp without time zone,NO,
student_enrollments,updated_at,timestamp without time zone,NO,
student_parents,id,bigint,NO,PRIMARY KEY
student_parents,student_id,bigint,NO,UNIQUE
student_parents,parent_id,bigint,NO,FOREIGN KEY
student_parents,relationship,character varying,NO,
student_parents,is_primary_contact,boolean,NO,
student_parents,is_emergency_contact,boolean,NO,
student_parents,created_at,timestamp without time zone,NO,
students,id,bigint,NO,PRIMARY KEY
students,admission_number,character varying,YES,UNIQUE
students,first_name,character varying,NO,
students,middle_name,character varying,YES,
students,last_name,character varying,NO,
students,date_of_birth,date,NO,
students,gender,character varying,NO,
students,birth_certificate_number,character varying,YES,UNIQUE
students,nationality,character varying,NO,
students,photo_url,character varying,YES,
students,status,character varying,NO,
students,created_at,timestamp without time zone,NO,
students,updated_at,timestamp without time zone,NO,
subjects,id,bigint,NO,PRIMARY KEY
subjects,name,character varying,NO,
subjects,code,character varying,YES,UNIQUE
subjects,category,character varying,YES,
subjects,is_compulsory,boolean,NO,
subjects,description,text,YES,
subjects,created_at,timestamp without time zone,NO,
system_users,id,bigint,NO,PRIMARY KEY
system_users,username,character varying,NO,UNIQUE
system_users,password_hash,character varying,NO,
system_users,role,character varying,NO,
system_users,staff_id,bigint,YES,FOREIGN KEY
system_users,student_id,bigint,YES,FOREIGN KEY
system_users,parent_id,bigint,YES,FOREIGN KEY
system_users,is_active,boolean,NO,
system_users,last_login,timestamp without time zone,YES,
system_users,must_change_password,boolean,NO,
system_users,created_at,timestamp without time zone,NO,
users,id,bigint,NO,PRIMARY KEY
users,email,character varying,YES,UNIQUE
users,username,character varying,YES,UNIQUE
users,password_hash,character varying,NO,
users,is_active,boolean,NO,
users,last_login,timestamp without time zone,YES,
users,created_at,timestamp without time zone,NO,
users,updated_at,timestamp without time zone,NO
"""

import sys

lines = csv_data.strip().split('\n')
tables = {}
for line in lines[1:]:
    parts = line.split(',')
    table_name = parts[0]
    col_name = parts[1]
    col_type = parts[2]
    is_nullable = parts[3]
    constraint = parts[4] if len(parts) > 4 else ""
    
    if table_name not in tables:
        tables[table_name] = []
    
    tables[table_name].append({
        'name': col_name,
        'type': col_type,
        'null': is_nullable,
        'constraint': constraint
    })

# Define the order of creation to avoid foreign key dependency issues
table_order = [
    'academic_years',
    'classes',
    'dormitories',
    'subjects',
    'schools',
    'users',
    'parents',
    'staff',
    'students',
    'exams',
    'exam_results',
    'fee_structure',
    'fee_payments',
    'attendance',
    'emergency_contacts',
    'hod_assignments',
    'notices',
    'staff_class_assignments',
    'staff_subjects',
    'student_admission_requests',
    'student_admissions',
    'student_boarding_assignments',
    'student_documents',
    'student_enrollments',
    'student_parents',
    'system_users'
]

# Simple mapping for common foreign keys to target tables
fk_targets = {
    'student_id': 'students(id)',
    'class_id': 'classes(id)',
    'academic_year_id': 'academic_years(id)',
    'exam_id': 'exams(id)',
    'subject_id': 'subjects(id)',
    'staff_id': 'staff(id)',
    'parent_id': 'parents(id)',
    'previous_school_id': 'schools(id)',
    'dormitory_id': 'dormitories(id)',
    'requested_class_id': 'classes(id)',
    'recorded_by': 'staff(id)',
    'received_by': 'staff(id)',
    'posted_by': 'staff(id)',
    'approved_by': 'staff(id)',
    'verified_by': 'staff(id)',
    'reviewed_by': 'staff(id)'
}

with open('schema_generated.sql', 'w') as f:
    f.write("-- GENERATED SCHEMA FROM LOCAL DATABASE\n\n")
    
    for t_name in table_order:
        if t_name not in tables:
            continue
            
        f.write(f"CREATE TABLE IF NOT EXISTS {t_name} (\n")
        cols = tables[t_name]
        
        col_defs = []
        for col in cols:
            # Type mapping (bigint PRIMARY KEY -> BIGSERIAL, integer PRIMARY KEY -> SERIAL)
            dtype = col['type']
            if dtype == 'character varying':
                dtype = 'VARCHAR(255)'
            elif dtype == 'timestamp without time zone':
                dtype = 'TIMESTAMP'
            elif dtype == 'timestamp with time zone':
                dtype = 'TIMESTAMPTZ'
                
            if col['constraint'] == 'PRIMARY KEY':
                if col['type'] == 'bigint':
                    dtype = 'BIGSERIAL'
                elif col['type'] == 'integer':
                    dtype = 'SERIAL'
            
            null_clause = "NOT NULL" if col['null'] == 'NO' else ""
            
            constraint_clause = ""
            if col['constraint'] == 'PRIMARY KEY':
                constraint_clause = "PRIMARY KEY"
            elif col['constraint'] == 'UNIQUE':
                constraint_clause = "UNIQUE"
            elif col['constraint'] == 'FOREIGN KEY':
                # Try to map foreign key
                target = fk_targets.get(col['name'], '')
                if target:
                    constraint_clause = f"REFERENCES {target}"
                    
            # Set a default for created_at and updated_at
            if col['name'] in ['created_at', 'updated_at']:
                constraint_clause = "DEFAULT CURRENT_TIMESTAMP" + (" " + constraint_clause if constraint_clause else "")
                
            # Set default for nationality
            if col['name'] == 'nationality':
                constraint_clause = "DEFAULT 'Kenyan'" + (" " + constraint_clause if constraint_clause else "")

                
            cdef = f"    {col['name']} {dtype} {null_clause} {constraint_clause}".strip()
            # replace multiple spaces
            cdef = ' '.join(cdef.split())
            col_defs.append("    " + cdef)
            
        f.write(",\n".join(col_defs))
        f.write("\n);\n\n")

print("Generated schema_generated.sql")
