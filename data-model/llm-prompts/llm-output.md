# LLM Output - CallDrop Data Model

## Design Rationale

### Partition Key Choice
- **User's phone number** as partition key ensures all calls from a user are stored together
- Enables efficient queries for a user's call history
- Distributes data across nodes based on phone numbers (good distribution for telecom data)

### Clustering Key Design
- **Destination number** + **Call timestamp** as clustering keys
- Allows queries for:
  - All calls from user A to user B
  - Calls within a time range
  - Most recent calls (DESC ordering)
- Timestamp as part of clustering key enables time-series queries

### Materialized View Strategy
- Create MV on `call_completed` to efficiently query successful/failed calls
- Maintains same partition key to avoid full cluster scans
- Useful for analytics on call success rates

## Schema Design

### Main Table: call_records

```cql
CREATE KEYSPACE IF NOT EXISTS calldrop 
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3
};

CREATE TABLE calldrop.call_records (
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
AND comment = 'Call tracking records for CallDrop telecom'
AND compaction = {'class': 'TimeWindowCompactionStrategy', 'compaction_window_size': 1, 'compaction_window_unit': 'DAYS'}
AND default_time_to_live = 7776000;  -- 90 days retention
```

### Materialized View: calls_by_completion

```cql
CREATE MATERIALIZED VIEW calldrop.calls_by_completion AS
    SELECT 
        source_phone_number,
        destination_number,
        call_timestamp,
        call_duration_seconds,
        source_cell_tower_id,
        destination_cell_tower_id,
        call_completed,
        source_phone_imei
    FROM calldrop.call_records
    WHERE call_completed IS NOT NULL
        AND source_phone_number IS NOT NULL
        AND destination_number IS NOT NULL
        AND call_timestamp IS NOT NULL
    PRIMARY KEY (call_completed, source_phone_number, destination_number, call_timestamp)
    WITH CLUSTERING ORDER BY (source_phone_number ASC, destination_number ASC, call_timestamp DESC);
```

### Alternative View: calls_by_time_range

```cql
-- Optional: For efficient time-range queries across all users
CREATE MATERIALIZED VIEW calldrop.calls_by_time AS
    SELECT 
        source_phone_number,
        destination_number,
        call_timestamp,
        call_duration_seconds,
        call_completed
    FROM calldrop.call_records
    WHERE call_timestamp IS NOT NULL
        AND source_phone_number IS NOT NULL
        AND destination_number IS NOT NULL
    PRIMARY KEY (call_timestamp, source_phone_number, destination_number)
    WITH CLUSTERING ORDER BY (source_phone_number ASC, destination_number ASC);
```

## Design Choices Explained

### 1. Replication Strategy
- **NetworkTopologyStrategy** with RF=3 for production
- Provides fault tolerance and high availability
- Each data center has 3 replicas

### 2. Clustering Order
- `destination_number ASC, call_timestamp DESC`
- Groups calls to same destination together
- Most recent calls appear first (DESC on timestamp)

### 3. Compaction Strategy
- **TimeWindowCompactionStrategy (TWCS)** for time-series data
- Efficient for data with TTL
- Better performance for time-range queries
- Reduces compaction overhead

### 4. TTL (Time To Live)
- Set to 90 days (7776000 seconds)
- Automatically removes old call records
- Reduces storage costs
- Adjust based on regulatory requirements

### 5. Materialized View Design
- Partition by `call_completed` (only 2 partitions: true/false)
- Include original partition key in clustering to maintain cardinality
- Enables efficient success rate calculations

## Sample Queries

### Query 1: All calls from a specific user
```cql
SELECT * FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890';
```

### Query 2: Calls from user to specific destination
```cql
SELECT * FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890' 
  AND destination_number = '+0987654321';
```

### Query 3: Recent calls from user in time range
```cql
SELECT * FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890' 
  AND destination_number = '+0987654321'
  AND call_timestamp >= '2024-01-01 00:00:00'
  AND call_timestamp <= '2024-01-31 23:59:59';
```

### Query 4: All successful calls
```cql
SELECT * FROM calldrop.calls_by_completion 
WHERE call_completed = true;
```

### Query 5: Failed calls for a specific user
```cql
SELECT * FROM calldrop.calls_by_completion 
WHERE call_completed = false 
  AND source_phone_number = '+1234567890';
```

### Query 6: Call success rate calculation
```cql
-- Count successful calls
SELECT COUNT(*) FROM calldrop.calls_by_completion 
WHERE call_completed = true 
  AND source_phone_number = '+1234567890';

-- Count total calls
SELECT COUNT(*) FROM calldrop.call_records 
WHERE source_phone_number = '+1234567890';
```

### Query 7: Calls in specific time range (using time-based MV)
```cql
SELECT * FROM calldrop.calls_by_time
WHERE call_timestamp >= '2024-01-01 00:00:00'
  AND call_timestamp <= '2024-01-01 23:59:59';
```

## Performance Considerations

### Efficient Queries
✅ Queries with partition key (source_phone_number)
✅ Queries with partition key + clustering key prefix
✅ Time-range queries within a partition
✅ Queries using materialized views

### Inefficient Queries (Avoid)
❌ Full table scans without partition key
❌ Queries on non-indexed columns (IMEI, tower IDs)
❌ Large time-range queries across many partitions

### Write Performance
- Single partition writes are very fast
- Materialized views add write overhead (2x writes)
- TWCS compaction optimized for time-series writes

### Read Performance
- Partition-level queries are O(1)
- Clustering key range scans are efficient
- Materialized views provide pre-computed indexes

## Potential Issues and Limitations

### 1. Hot Partitions
**Issue**: Users with very high call volumes create large partitions
**Solution**: 
- Monitor partition sizes
- Consider bucketing by time (e.g., source_phone_number + date)
- Alert on partitions > 100MB

### 2. Materialized View Overhead
**Issue**: MVs double write load
**Solution**:
- Only create MVs for critical query patterns
- Consider application-level indexing for less critical queries
- Monitor MV sync lag

### 3. Time-Range Queries Across Users
**Issue**: Queries across all users in time range require full scan
**Solution**:
- Use calls_by_time materialized view
- Or implement application-level time bucketing
- Consider separate analytics table with different partition key

### 4. TTL and Data Retention
**Issue**: Regulatory requirements may need longer retention
**Solution**:
- Adjust TTL based on requirements
- Consider archiving to cold storage (S3)
- Implement tiered storage strategy

### 5. IMEI and Tower ID Queries
**Issue**: No efficient way to query by IMEI or tower ID
**Solution**:
- Create additional MVs if these queries are critical
- Or use secondary indexes (with caution)
- Consider separate lookup tables

## Scaling Considerations

### Current Scale (15 users, 20-25 calls each)
- ~375-400 records
- Minimal storage (~50KB)
- Any configuration will work

### Production Scale (Millions of records)
- Monitor partition sizes
- Tune compaction settings
- Consider time-based bucketing
- Implement data archival strategy
- Use monitoring for hot partition detection

## Recommended Indexes

### When to Add Secondary Indexes
Only if absolutely necessary, as they impact write performance:

```cql
-- Example: If IMEI queries are critical
CREATE INDEX ON calldrop.call_records (source_phone_imei);

-- Example: If tower queries are needed
CREATE INDEX ON calldrop.call_records (source_cell_tower_id);
```

**Note**: Secondary indexes in Cassandra/Scylla are expensive. Prefer materialized views or application-level solutions.

## Summary

This schema design provides:
- ✅ Efficient user-centric queries
- ✅ Time-series query support
- ✅ Call completion status filtering
- ✅ Scalability to millions of records
- ✅ Automatic data retention (TTL)
- ✅ Optimized compaction for time-series data

The design balances query flexibility with write performance, making it suitable for a high-volume telecommunications call tracking system.