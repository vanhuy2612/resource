alter session set "_ORACLE_SCRIPT"=true; 
CREATE USER remote IDENTIFIED BY 123456;
GRANT CONNECT TO remote;

ALTER USER sys quota unlimited ON USERS;
ALTER USER remote quota unlimited ON USERS;

create table REMOTE."User" (
	ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
	NAME VARCHAR2(100) NULL
);