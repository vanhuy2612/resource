1. Run docker-compose.yml
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
{topic.prefix=FLEX_2_ELASTIC_SEARCH, database.user=remote, database.dbname=XE, schema.history.internal.kafka.topic=FLEX_HIS, database.hostname=oracle, database.pdb.name=REMOTE, database.password=********, schema.history.internal.kafka.bootstrap.servers=10.100.30.105:39091,10.100.30.105:39092,10.100.30.105:39093, database.port=1521}