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

select *from Students;
/d