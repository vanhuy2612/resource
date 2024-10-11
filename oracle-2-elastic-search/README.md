1. Run docker-compose.yml
  Run Oracle CLI docker : sqlplus
  Tạo user fix lỗi chạy sys.dbms_logmnr.... user not exist:
-- create admin user on CDB
CREATE USER c##remote IDENTIFIED BY 123456 DEFAULT TABLESPACE users QUOTA UNLIMITED ON users ACCOUNT UNLOCK
-- allow access to all PDBs to the admin user
ALTER USER c##remote SET CONTAINER_DATA=ALL CONTAINER=CURRENT

-- grant needed permissions
GRANT RESOURCE, CONNECT TO c##remote;
GRANT CREATE SESSION TO c##remote;
GRANT SET CONTAINER TO c##remote;
GRANT SELECT ON V_$DATABASE to c##remote;
GRANT FLASHBACK ANY TABLE TO c##remote;
GRANT SELECT ANY TABLE TO c##remote;
GRANT SELECT_CATALOG_ROLE TO c##remote;
GRANT EXECUTE_CATALOG_ROLE TO c##remote; 
GRANT SELECT ANY TRANSACTION TO c##remote;
GRANT LOGMINING TO c##remote;

GRANT CREATE TABLE TO c##remote;
GRANT LOCK ANY TABLE TO c##remote;
GRANT CREATE SEQUENCE TO c##remote;

GRANT EXECUTE ON SYS.DBMS_LOGMNR TO c##remote;
GRANT EXECUTE ON SYS.DBMS_LOGMNR_D TO c##remote;
GRANT EXECUTE ON DBMS_LOGMNR TO c##remote;
GRANT EXECUTE ON DBMS_LOGMNR_D TO c##remote;

GRANT SELECT ON V_$LOG TO c##remote;
GRANT SELECT ON V_$LOG_HISTORY TO c##remote;
GRANT SELECT ON V_$LOGMNR_LOGS TO c##remote;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO c##remote;
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO c##remote;
GRANT SELECT ON V_$LOGFILE TO c##remote;
GRANT SELECT ON V_$ARCHIVED_LOG TO c##remote;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO c##remote;
GRANT SELECT ON V_$TRANSACTION TO c##remote;
GRANT SELECT ANY DICTIONARY TO c##remote;

-- SELECT 
SELECT * FROM dba_users;
DROP USER c##remote CASCADE;
SELECT banner FROM v$version WHERE ROWNUM = 1;

SELECT * FROM USER_SYS_PRIVS WHERE USERNAME = 'C##REMOTE'; 
SELECT * FROM USER_TAB_PRIVS WHERE GRANTEE ='C##REMOTE';
SELECT * FROM USER_ROLE_PRIVS;
select * from session_roles;
SELECT * FROM all_objects WHERE object_name = 'DBMS_LOGMNR';

2. Combine Oracle with Debezium:
+ Connect to Oracle as an admin : ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
+ Enable ARCHIVELOG mode : 
    SELECT log_mode FROM v$database;
    -- If not in ARCHIVELOG mode, switch to ARCHIVELOG mode:
    SHUTDOWN IMMEDIATE;
    STARTUP MOUNT;
    ALTER DATABASE ARCHIVELOG;
    ALTER DATABASE OPEN;
+ Set up Redo/Undo Logging
    ALTER SYSTEM SWITCH LOGFILE;
3. Set up Debezium
Create connect between Oracle and Debezium
POST :  http://localhost:8083/connectors 
body: {
  "name": "oracle-connector",               // Unique name for the connector
  "config": {
    "connector.class": "io.debezium.connector.oracle.OracleConnector",
    "tasks.max": "1",                       // Number of tasks to run
    "database.hostname": "localhost",       // Oracle database hostname (service's name in docker)
    "database.port": "1521",                // Oracle port
    "database.user": "debezium",            // Oracle user with proper privileges
    "database.password": "password",        // Oracle user password
    "database.dbname": "XE",                // Oracle database name (SID)
    "database.pdb.name": "pdb1",            // (Optional) Pluggable DB name, if applicable
    "database.connection.adapter": "logminer",  // Use "logminer" or "xstream"
    "database.out.server.name": "dbserver1",    // Logical name for the Oracle server
    "database.history.kafka.bootstrap.servers": "kafka:9092", // Kafka cluster to store schema history
    "database.history.kafka.topic": "schema-changes.inventory", // Topic for schema changes
    "table.include.list": "inventory.customers",  // List of tables to capture changes
    "database.stream.offset.storage": "file:///data/offsets.dat",  // Offset storage (file or Kafka)
    "database.stream.offset.flush.interval.ms": "1000"
  }
}
{topic.prefix=FLEX_2_ELASTIC_SEARCH, database.user=remote, database.dbname=XE, schema.history.internal.kafka.topic=FLEX_HIS, database.hostname=oracle, database.pdb.name=, database.password=********, schema.history.internal.kafka.bootstrap.servers=10.100.30.105:39091,10.100.30.105:39092,10.100.30.105:39093, database.port=1521}