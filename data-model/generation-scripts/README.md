# CallDrop Data Generation Scripts

## Overview
This directory contains scripts to generate sample call data for the CallDrop system.

## Files

- `generate-call-data.py` - Main data generation script
- `requirements.txt` - Python dependencies
- `README.md` - This file

## Prerequisites

### Python 3
Ensure Python 3.7+ is installed:
```bash
python3 --version
```

### Install Dependencies
```bash
pip3 install -r requirements.txt
```

Or install manually:
```bash
pip3 install cassandra-driver
```

## Usage

### Basic Usage (Local)
```bash
python3 generate-call-data.py
```

This connects to `127.0.0.1` by default.

### Specify Scylla Nodes
```bash
python3 generate-call-data.py "10.0.1.10,10.0.1.11,10.0.1.12"
```

### Make Script Executable
```bash
chmod +x generate-call-data.py
./generate-call-data.py "node1-ip,node2-ip,node3-ip"
```

## What the Script Does

1. **Connects to Scylla Cluster**
   - Uses provided node IPs or defaults to localhost
   - Connects to the `calldrop` keyspace

2. **Generates Users**
   - Creates 15 unique phone numbers
   - Uses various area codes (+1234, +1235, etc.)

3. **Generates Call Records**
   - 20-25 calls per user
   - Random timestamps within last 30 days
   - Random destinations
   - Random call durations (0-3600 seconds)
   - 85% success rate (15% failed calls)
   - Random cell tower assignments
   - Unique IMEI numbers

4. **Inserts Data**
   - Uses batch statements for efficiency
   - Batch size: 50 records
   - Consistency level: QUORUM

5. **Verifies Data**
   - Counts total records
   - Shows sample data
   - Displays statistics

## Configuration

Edit the script to modify:

```python
# Number of users
NUM_USERS = 15

# Calls per user range
MIN_CALLS_PER_USER = 20
MAX_CALLS_PER_USER = 25

# Area codes for phone numbers
AREA_CODES = ['+1234', '+1235', '+1236', '+1237', '+1238']

# Cell tower pool
CELL_TOWERS = [f'TOWER-{str(i).zfill(3)}' for i in range(1, 101)]
```

## Sample Output

```
============================================================
CallDrop Data Generation Script
============================================================

Configuration:
  Scylla Nodes: 10.0.1.10, 10.0.1.11, 10.0.1.12
  Keyspace: calldrop
  Number of Users: 15
  Calls per User: 20-25

Connecting to Scylla cluster...
✓ Connected successfully

Generating 15 users...
✓ Users generated
  Sample users: ['+12345678901', '+12356789012', '+12367890123']

Generating call records...
✓ Generated 345 call records

Inserting records into Scylla...
Inserted 345/345 records...
✓ All records inserted successfully

Verifying data...
✓ Total records in database: 345

Sample records:

Calls from +12345678901:
----------------------------------------------------------------------------------------------------
✓ To: +12378901234 | Time: 2024-01-15 10:30:45 | Duration: 125s | Towers: TOWER-023 -> TOWER-067
✓ To: +12389012345 | Time: 2024-01-14 15:22:10 | Duration: 456s | Towers: TOWER-045 -> TOWER-089
✗ To: +12340123456 | Time: 2024-01-13 08:15:30 | Duration: 12s | Towers: TOWER-012 -> TOWER-034
✓ To: +12351234567 | Time: 2024-01-12 20:45:00 | Duration: 789s | Towers: TOWER-078 -> TOWER-091
✓ To: +12362345678 | Time: 2024-01-11 12:30:15 | Duration: 234s | Towers: TOWER-056 -> TOWER-023

Statistics:
  Total Calls: 345
  Successful: 293 (84.9%)
  Failed: 52 (15.1%)

============================================================
Data generation complete!
============================================================
```

## Data Characteristics

### Phone Numbers
- Format: `+[area_code][7-digit-number]`
- Example: `+12345678901`
- 15 unique source numbers
- Random destination numbers

### Call Timestamps
- Distributed over last 30 days
- Random times throughout the day
- Stored in UTC

### Call Duration
- Successful calls: 10-3600 seconds (up to 1 hour)
- Failed calls: 0-30 seconds
- Average successful call: ~1800 seconds (30 minutes)

### Success Rate
- 85% of calls complete successfully
- 15% fail (short duration)
- Realistic for telecom data

### Cell Towers
- Pool of 100 towers (TOWER-001 to TOWER-100)
- Random assignment for source and destination
- Can be same or different towers

### IMEI Numbers
- 15-digit unique identifiers
- One per call record
- Format: `123456789012345`

## Verifying Generated Data

### Count Records
```bash
cqlsh <node-ip> -e "SELECT COUNT(*) FROM calldrop.call_records;"
```

### View Sample Data
```bash
cqlsh <node-ip> -e "SELECT * FROM calldrop.call_records LIMIT 10;"
```

### Check Specific User
```bash
cqlsh <node-ip> -e "SELECT * FROM calldrop.call_records WHERE source_phone_number = '+12345678901';"
```

### Check Success Rate
```bash
# Successful calls
cqlsh <node-ip> -e "SELECT COUNT(*) FROM calldrop.calls_by_completion WHERE call_completed = true;"

# Failed calls
cqlsh <node-ip> -e "SELECT COUNT(*) FROM calldrop.calls_by_completion WHERE call_completed = false;"
```

## Troubleshooting

### Connection Error
```
✗ Failed to connect: No hosts available
```

**Solutions:**
- Verify Scylla nodes are running: `nodetool status`
- Check node IPs are correct
- Verify firewall allows port 9042
- Test connection: `cqlsh <node-ip>`

### Keyspace Not Found
```
✗ Failed to connect: Keyspace 'calldrop' does not exist
```

**Solution:**
```bash
cqlsh <node-ip> -f ../../schema/create-schema.cql
```

### Import Error
```
ModuleNotFoundError: No module named 'cassandra'
```

**Solution:**
```bash
pip3 install cassandra-driver
```

### Permission Denied
```
PermissionError: [Errno 13] Permission denied
```

**Solution:**
```bash
chmod +x generate-call-data.py
```

## Advanced Usage

### Custom Number of Users
Edit the script:
```python
NUM_USERS = 50  # Generate 50 users instead of 15
```

### Custom Call Range
```python
MIN_CALLS_PER_USER = 50
MAX_CALLS_PER_USER = 100
```

### Custom Time Range
Edit the `generate_call_record` function:
```python
# Change from 30 days to 90 days
time_offset = timedelta(
    days=random.randint(0, 89),  # 0-89 days
    hours=random.randint(0, 23),
    minutes=random.randint(0, 59),
    seconds=random.randint(0, 59)
)
```

### Custom Success Rate
```python
# Change from 85% to 90% success rate
call_completed = random.random() > 0.10  # 90% success
```

## Performance Considerations

### Batch Size
- Default: 50 records per batch
- Increase for faster insertion (may impact cluster)
- Decrease if seeing timeouts

### Consistency Level
- Default: QUORUM (2 out of 3 nodes)
- Change to ONE for faster writes (less durability)
- Change to ALL for maximum durability (slower)

### Connection Pooling
The script uses default connection pooling from cassandra-driver.

## Cleanup

### Delete All Data
```bash
cqlsh <node-ip> -e "TRUNCATE calldrop.call_records;"
```

### Drop and Recreate
```bash
cqlsh <node-ip> -e "DROP KEYSPACE IF EXISTS calldrop;"
cqlsh <node-ip> -f ../../schema/create-schema.cql
```

## Next Steps

After generating data:
1. Verify data in Scylla Monitoring dashboards
2. Run analytics queries (see `../../../analytics/scripts/`)
3. Test query performance
4. Monitor shard distribution

## References

- [Cassandra Python Driver](https://docs.datastax.com/en/developer/python-driver/)
- [Scylla Best Practices](https://docs.scylladb.com/stable/using-scylla/best-practices/)