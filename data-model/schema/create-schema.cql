-- CallDrop Database Schema
-- Scylla/Cassandra CQL Schema for Call Tracking System

-- Create Keyspace
CREATE KEYSPACE IF NOT EXISTS calldrop 
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3
}
AND durable_writes = true;

-- Use the keyspace
USE calldrop;

-- Main Table: Call Records
-- Stores all call information with user's phone number as partition key
CREATE TABLE IF NOT EXISTS call_records (
    source_phone_number TEXT,
    destination_number TEXT,
    call_timestamp TIMESTAMP,
    call_duration_seconds INT,
    source_cell_tower_id TEXT,
    destination_cell_tower_id TEXT,
    call_completed BOOLEAN,
    source_phone_imei TEXT,
    PRIMARY KEY (source_phone_number, destination_number, call_timestamp)
) WITH CLUSTERING ORDER BY (destination_number ASC, call_timestamp DESC)
AND comment = 'Call tracking records for CallDrop telecom provider'
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
}
AND default_time_to_live = 7776000  -- 90 days retention (in seconds)
AND gc_grace_seconds = 864000;      -- 10 days

-- Materialized View: Calls by Completion Status
-- Enables efficient queries for successful/failed calls
CREATE MATERIALIZED VIEW IF NOT EXISTS calls_by_completion AS
    SELECT 
        source_phone_number,
        destination_number,
        call_timestamp,
        call_duration_seconds,
        source_cell_tower_id,
        destination_cell_tower_id,
        call_completed,
        source_phone_imei
    FROM call_records
    WHERE call_completed IS NOT NULL
        AND source_phone_number IS NOT NULL
        AND destination_number IS NOT NULL
        AND call_timestamp IS NOT NULL
    PRIMARY KEY (call_completed, source_phone_number, destination_number, call_timestamp)
    WITH CLUSTERING ORDER BY (source_phone_number ASC, destination_number ASC, call_timestamp DESC)
    AND comment = 'Materialized view for querying calls by completion status';

-- Display schema information
DESCRIBE KEYSPACE calldrop;
DESCRIBE TABLE call_records;
DESCRIBE MATERIALIZED VIEW calls_by_completion;