-- Database: kwale_high_school

-- DROP DATABASE IF EXISTS kwale_high_school;

CREATE DATABASE kwale_high_school
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_Malaysia.1252'
    LC_CTYPE = 'English_Malaysia.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE kwale_high_school
    IS 'Kwale High School Database';


SELECT 
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    (
        SELECT tc.constraint_type 
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
          AND kcu.table_name = c.table_name
          AND kcu.column_name = c.column_name
        LIMIT 1
    ) AS constraint_type
FROM 
    information_schema.columns c
WHERE 
    c.table_schema = 'public'
ORDER BY 
    c.table_name, c.ordinal_position;
