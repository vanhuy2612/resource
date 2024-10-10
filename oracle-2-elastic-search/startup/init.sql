alter session set "_ORACLE_SCRIPT"=true; 

-- Carefully: this will change ARCHIVELOG Mode, need admin permission
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ALTER SYSTEM SWITCH LOGFILE;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

-- CREATE USER
CREATE USER remote IDENTIFIED BY 123456;
ALTER USER remote quota unlimited ON USERS;

-- CREATE ROLE AND ASSIGN TO REMOTE
alter session set "_ORACLE_SCRIPT"=true; 
GRANT EXECUTE ON sys.dbms_logmnr TO remote;
GRANT EXECUTE ON DBMS_LOGMNR_D TO remote;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO remote;
GRANT SELECT ON V_$LOG TO remote;
GRANT SELECT ON V_$LOGFILE TO remote;
GRANT SELECT ON V_$ARCHIVED_LOG TO remote;
GRANT SELECT ON V_$PARAMETER TO remote;
GRANT SELECT ON V_$DATABASE TO remote;
GRANT SELECT ON V_$LOG_HISTORY TO remote;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO remote;
GRANT SELECT ON V_$LOGMNR_LOGS TO remote;
GRANT SELECT ON V_$THREAD TO remote;
GRANT SELECT ANY DICTIONARY TO remote;
GRANT SELECT ON V_$STATNAME TO remote;
GRANT SELECT ON V_$MYSTAT TO remote;
GRANT SELECT ON V_$SESSION TO remote;

GRANT RESOURCE TO remote;
GRANT CONNECT TO remote;
GRANT CREATE TABLE TO remote;
GRANT CREATE SESSION TO remote;
GRANT SELECT ANY TRANSACTION TO remote;

create table REMOTE."User" (
	ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
	NAME VARCHAR2(100) NULL
);