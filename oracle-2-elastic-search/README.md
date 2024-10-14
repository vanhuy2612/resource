1. Run docker-compose.yml
  NOTE: KHÔNG được phép tạo user bằng chế độ : alter session set "_ORACLE_SCRIPT"=true; 
  Run Oracle CLI docker : sqlplus
  Tạo user fix lỗi chạy sys.dbms_logmnr.... user not exist, phải tạo theo format c##<username>:
-- 1. Chuyển DB sang chế độ ARCHIVELOG Mode
-- Carefully: this will change ARCHIVELOG Mode, need admin permission
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ALTER SYSTEM SWITCH LOGFILE;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- 2. Tạo user cho debezium, chạy bằng user sys or admin
-- create admin user on CDB
CREATE USER c##remote IDENTIFIED BY 123456 CONTAINER=ALL ;

-- 3. Gán quyền cần thiết cho user debezium vừa tạo, chạy bằng user sys or admin
-- grant needed permissions
GRANT RESOURCE,
	CONNECT,
	CREATE SESSION,
    ALTER SESSION,
    CREATE TABLE,
    UNLIMITED TABLESPACE,
    CREATE SEQUENCE,
    CREATE VIEW
    TO c##remote container=all;

-- privileges for execute LogMiner
GRANT LOGMINING TO c##remote;
GRANT EXECUTE_CATALOG_ROLE TO c##remote; 
GRANT EXECUTE ON SYS.DBMS_LOGMNR TO c##remote container=all;
GRANT EXECUTE ON DBMS_LOGMNR_D TO c##remote container=all;

-- SELECT_CATALOG_ROLE dùng để lấy dbms_metadata.get_ddl của schema khác 
GRANT SELECT_CATALOG_ROLE TO c##remote container=all;
-- privileges for read LogMiner
GRANT SELECT ON V_$DATABASE to c##remote container=all;
GRANT SELECT ON V_$LOG TO c##remote container=all;
GRANT SELECT ON V_$LOG_HISTORY TO c##remote container=all;
GRANT SELECT ON V_$LOGMNR_LOGS TO c##remote container=all;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO c##remote container=all;
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO c##remote container=all;
GRANT SELECT ON V_$LOGFILE TO c##remote container=all;
GRANT SELECT ON V_$ARCHIVED_LOG TO c##remote container=all;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO c##remote container=all;
GRANT SELECT ON V_$TRANSACTION TO c##remote container=all;
GRANT SELECT ON V_$LOGMNR_DICTIONARY TO c##remote container=all;
GRANT SELECT ANY DICTIONARY TO c##remote container=all;

-- 4.Gán các quyền truy cập vào schema khác cho user debezium
-- Asign all privileges to other schema
BEGIN
   FOR objects IN
   (
         SELECT 'GRANT ALL ON "'||owner||'"."'||object_name||'" TO c##remote' grantSQL
           FROM all_objects
          WHERE owner = 'C##REMOTE_1'
            AND object_type NOT IN
                (
                   --Ungrantable objects.  Your schema may have more.
                   'SYNONYM', 'INDEX', 'INDEX PARTITION', 'DATABASE LINK',
                   'LOB', 'TABLE PARTITION', 'TRIGGER'
                )
       ORDER BY object_type, object_name
   ) LOOP
      BEGIN
         EXECUTE IMMEDIATE objects.grantSQL;
      EXCEPTION WHEN OTHERS THEN
         --Ignore ORA-04063: view "X.Y" has errors.
         --(You could potentially workaround this by creating an empty view,
         -- granting access to it, and then recreat the original view.) 
         IF SQLCODE IN (-4063) THEN
            NULL;
         --Raise exception along with the statement that failed.
         ELSE
            raise_application_error(-20000, 'Problem with this statement: ' ||
               objects.grantSQL || CHR(10) || SQLERRM);
         END IF;
      END;
   END LOOP;
END;

2. Combine Oracle with Debezium:
Note:
+ Khi cài đặt Mapping properties: 
Decimal handling -> option double // Ex: AQ== tương đương với 1
....
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