# CallDrop Database Schema

## Overview
This directory contains the CQL schema definitions for the CallDrop call tracking system.

## Schema Files

### create-schema.cql
Complete schema definition including:
- Keyspace creation
- Main call_records table
- Materialized view for call completion status

## Schema Structure

### Keyspace: calldrop
- **Replication Strategy**: NetworkTopologyStrategy
- **Replication Factor**: 3 (for datacenter1)
- **Durable Writes**: Enabled

### Table: call_records

#### Columns
| Column Name | Type | Description |
|------------|------|-------------|
| source_phone_number | TEXT | User's phone number (Partition Key) |
| destination_number | TEXT | Called number (Clustering Key 1) |
| call_timestamp | TIMESTAMP | When call was made (Clustering Key 2) |
| call_duration_seconds | INT | Duration of call in seconds |
| source_cell_tower_id | TEXT | Source tower identifier |
| destination_cell_tower_id | TEXT | Destination tower identifier |
| call_completed | BOOLEAN | Whether call completed successfully |
| source_phone_imei | TEXT | IMEI of source device |

#### Primary Key
```
PRIMARY KEY (source_phone_number, destination_number, call_timestamp)
```

#### Clustering Order
```
CLUSTERING ORDER BY (destination_number ASC, call_timestamp DESC)
```

#### Table Properties
- **Compaction**: TimeWindowCompactionStrategy (1 day window)
- **TTL**: 90 days (7776000 seconds)
- **GC Grace Seconds**: 10 days (864000 seconds)

### Materialized View: calls_by_completion

Enables efficient queries by call completion status.

#### Primary Key
```
PRIMARY KEY (call_completed, source_phone_number, destination_number, call_timestamp)
```

#### Clustering Order
```
CLUSTERING ORDER BY (source_phone_number ASC, destination_number ASC, call_timestamp DESC)
```

## Applying the Schema

### Method 1: Using cqlsh
```bash
# Connect to any Scylla node
cqlsh <node-ip>

# Execute the schema file
SOURCE '/path/to/create-schema.cql';
```

### Method 2: Using cqlsh with file
```bash
cqlsh <node-ip> -f create-schema.cql
```

### Method 3: Remote execution
```bash
cqlsh <node-ip> < create-schema.cql
```

## Verifying Schema

### Check Keyspace
```cql
DESCRIBE KEYSPACE calldrop;
```

### Check Table
```cql
USE calldrop;
DESCRIBE TABLE call_records;
```

### Check Materialized View
```cql
DESCRIBE MATERIALIZED VIEW calls_by_completion;
```

### List All Tables
```cql
USE calldrop;
DESCRIBE TABLES;
```

## Query Examples

### Insert Sample Data
```cql
INSERT INTO calldrop.call_records (
    source_phone_number,
    destination_number,
    call_timestamp,
    call_duration_seconds,
    source_cell_tower_id,
    destination_cell_tower_id,
    call_completed,
    source_phone_imei
) VALUES (
    '+1234567890',
    '+0987654321',
    '2024-01-15 10:30:00',
    125,
    'TOWER-001',
    'TOWER-045',
    true,
    '123456789012345'
);
```

### Query All Calls from User
```cql
SELECT * FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890';
```

### Query Calls to Specific Destination
```cql
SELECT * FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890' 
  AND destination_number = '+0987654321';
```

### Query Successful Calls
```cql
SELECT * FROM calldrop.calls_by_completion 
WHERE call_completed = true 
LIMIT 100;
```

### Query Failed Calls for User
```cql
SELECT * FROM calldrop.calls_by_completion 
WHERE call_completed = false 
  AND source_phone_number = '+1234567890';
```

### Count Total Calls
```cql
SELECT COUNT(*) FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890';
```

## Schema Design Decisions

### Partition Key: source_phone_number
- Groups all calls from a user together
- Enables efficient user-centric queries
- Good distribution across cluster

### Clustering Keys: destination_number, call_timestamp
- Allows queries for specific destinations
- Enables time-range queries
- DESC ordering shows most recent calls first

### Materialized View
- Pre-computes index on call_completed
- Enables efficient success rate calculations
- Maintains partition key for good distribution

### Compaction Strategy
- TimeWindowCompactionStrategy for time-series data
- Optimized for data with TTL
- Reduces compaction overhead

### TTL (Time To Live)
- 90-day retention for call records
- Automatic cleanup of old data
- Reduces storage costs

## Performance Considerations

### Efficient Queries
✅ Queries with partition key
✅ Queries with partition + clustering key prefix
✅ Time-range queries within partition
✅ Queries using materialized view

### Queries to Avoid
❌ Full table scans
❌ Queries without partition key
❌ Queries on non-indexed columns

## Monitoring

### Check Table Statistics
```cql
SELECT * FROM system.size_estimates 
WHERE keyspace_name = 'calldrop';
```

### Check Compaction Stats
```bash
nodetool compactionstats
```

### Check Table Info
```bash
nodetool tablestats calldrop.call_records
```

## Maintenance

### Manual Compaction (if needed)
```bash
nodetool compact calldrop call_records
```

### Repair Table
```bash
nodetool repair calldrop call_records
```

### Flush Memtables
```bash
nodetool flush calldrop call_records
```

## Schema Modifications

### Adding a Column
```cql
ALTER TABLE calldrop.call_records 
ADD call_quality_score INT;
```

### Modifying TTL
```cql
ALTER TABLE calldrop.call_records 
WITH default_time_to_live = 15552000;  -- 180 days
```

### Dropping Materialized View
```cql
DROP MATERIALIZED VIEW IF EXISTS calldrop.calls_by_completion;
```

## Backup and Restore

### Backup Schema
```bash
cqlsh <node-ip> -e "DESCRIBE KEYSPACE calldrop" > calldrop-schema-backup.cql
```

### Export Data
```bash
# Using COPY command
cqlsh <node-ip> -e "COPY calldrop.call_records TO 'call_records.csv'"
```

## Troubleshooting

### Schema Not Applied
- Check cqlsh connection
- Verify node is up: `nodetool status`
- Check logs: `journalctl -u scylla-server`

### Materialized View Not Syncing
- Check MV status: `SELECT * FROM system_distributed.view_build_status;`
- Rebuild if needed: `nodetool rebuild_view calldrop calls_by_completion`

### High Write Latency
- Check compaction: `nodetool compactionstats`
- Monitor disk I/O
- Consider adjusting compaction settings

## Next Steps

After schema creation:
1. Generate sample data (see `../generation-scripts/`)
2. Verify data insertion
3. Test query patterns
4. Monitor performance in Grafana

## References

- [Scylla CQL Reference](https://docs.scylladb.com/stable/cql/)
- [Data Modeling Best Practices](https://docs.scylladb.com/stable/data-modeling/)
- [Materialized Views](https://docs.scylladb.com/stable/cql/mv.html)