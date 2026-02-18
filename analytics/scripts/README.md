# CallDrop Analytics Scripts

## Overview
This directory contains analytics scripts for querying and analyzing call data from the CallDrop Scylla database.

## Scripts

### call-success-rate.go
Go program that calculates the percentage of successfully completed phone calls within a specified time range, with optional filtering by phone number.

## Prerequisites

### Go Installation
Ensure Go 1.21+ is installed:
```bash
go version
```

Install Go from: https://golang.org/dl/

### Dependencies
Install required Go modules:
```bash
cd analytics/scripts
go mod download
```

## Usage

### Build the Program
```bash
go build call-success-rate.go
```

### Run Directly (Development)
```bash
go run call-success-rate.go [flags]
```

### Run Compiled Binary
```bash
./call-success-rate [flags]
```

## Command Line Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--nodes` | No | 127.0.0.1 | Comma-separated list of Scylla node IPs |
| `--keyspace` | No | calldrop | Keyspace name |
| `--start-time` | Yes | - | Start time in RFC3339 format |
| `--end-time` | Yes | - | End time in RFC3339 format |
| `--phone-number` | No | - | Filter by specific phone number |

## Examples

### Example 1: All Users in Time Range
```bash
go run call-success-rate.go \
  --nodes=10.0.1.10,10.0.1.11,10.0.1.12 \
  --start-time=2024-01-01T00:00:00Z \
  --end-time=2024-01-31T23:59:59Z
```

### Example 2: Specific User in Time Range
```bash
go run call-success-rate.go \
  --nodes=10.0.1.10,10.0.1.11,10.0.1.12 \
  --start-time=2024-01-15T00:00:00Z \
  --end-time=2024-01-15T23:59:59Z \
  --phone-number=+1234567890
```

### Example 3: Last 24 Hours (All Users)
```bash
# Calculate timestamps
START_TIME=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

go run call-success-rate.go \
  --nodes=10.0.1.10 \
  --start-time=$START_TIME \
  --end-time=$END_TIME
```

### Example 4: Specific Hour Range
```bash
go run call-success-rate.go \
  --nodes=10.0.1.10 \
  --start-time=2024-01-15T09:00:00Z \
  --end-time=2024-01-15T17:00:00Z
```

### Example 5: Local Development
```bash
go run call-success-rate.go \
  --start-time=2024-01-01T00:00:00Z \
  --end-time=2024-01-31T23:59:59Z
```

## Sample Output

### Output for All Users
```
Connecting to Scylla cluster...
  Nodes: 10.0.1.10, 10.0.1.11, 10.0.1.12
  Keyspace: calldrop

✓ Connected successfully

Calculating call success rate...
  Time Range: 2024-01-01T00:00:00Z to 2024-01-31T23:59:59Z
  Phone Number: All users

Found 15 users, analyzing calls...

======================================================================
CALL SUCCESS RATE ANALYSIS
======================================================================

Time Range:
  Start: 2024-01-01 00:00:00 UTC
  End:   2024-01-31 23:59:59 UTC
  Duration: 30 days, 23 hours, 59 minutes

Filter:
  Phone Number: All users

Results:
----------------------------------------------------------------------
  Total Calls:       345
  Successful Calls:  293
  Failed Calls:      52
----------------------------------------------------------------------
  Success Rate:      84.93%
  Failure Rate:      15.07%
======================================================================

Visual Representation:
  Successful ✓ [██████████████████████████████████████████████░░░░░░░░]    293 (84.9%)
  Failed ✗     [███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]     52 (15.1%)
```

### Output for Specific User
```
Connecting to Scylla cluster...
  Nodes: 10.0.1.10
  Keyspace: calldrop

✓ Connected successfully

Calculating call success rate...
  Time Range: 2024-01-15T00:00:00Z to 2024-01-15T23:59:59Z
  Phone Number: +1234567890

======================================================================
CALL SUCCESS RATE ANALYSIS
======================================================================

Time Range:
  Start: 2024-01-15 00:00:00 UTC
  End:   2024-01-15 23:59:59 UTC
  Duration: 23 hours, 59 minutes

Filter:
  Phone Number: +1234567890

Results:
----------------------------------------------------------------------
  Total Calls:       23
  Successful Calls:  20
  Failed Calls:      3
----------------------------------------------------------------------
  Success Rate:      86.96%
  Failure Rate:      13.04%
======================================================================

Visual Representation:
  Successful ✓ [███████████████████████████████████████████░░░░░░░░░]     20 (87.0%)
  Failed ✗     [██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]      3 (13.0%)
```

## How It Works

### 1. Connection
- Connects to Scylla cluster using provided node IPs
- Uses QUORUM consistency level
- 10-second timeout for queries

### 2. Data Retrieval
- **For specific user**: Queries `call_records` table with partition key
- **For all users**: 
  - First retrieves all unique phone numbers
  - Then queries each user's calls in the time range

### 3. Calculation
- Counts total calls in time range
- Counts successful calls (call_completed = true)
- Counts failed calls (call_completed = false)
- Calculates success rate percentage

### 4. Output
- Displays time range and filter information
- Shows call statistics
- Calculates success/failure rates
- Provides visual bar chart representation

## Performance Considerations

### Query Efficiency
- **Specific user queries**: Very efficient (uses partition key)
- **All users queries**: Less efficient (requires multiple queries)

### Optimization Tips
1. **Use phone number filter** when possible for better performance
2. **Limit time ranges** to reduce data scanned
3. **Consider materialized views** for frequent all-user queries
4. **Monitor query latency** in Grafana

### Scalability
- Current implementation queries each user sequentially
- For production with many users, consider:
  - Parallel queries with goroutines
  - Batch processing
  - Pre-aggregated statistics tables

## Time Format

### RFC3339 Format
The script uses RFC3339 format for timestamps:
```
YYYY-MM-DDTHH:MM:SSZ
```

Examples:
- `2024-01-01T00:00:00Z` - January 1, 2024, midnight UTC
- `2024-01-15T14:30:00Z` - January 15, 2024, 2:30 PM UTC
- `2024-12-31T23:59:59Z` - December 31, 2024, 11:59:59 PM UTC

### Converting from Other Formats

#### From Unix Timestamp
```bash
date -u -d @1704067200 +%Y-%m-%dT%H:%M:%SZ
```

#### From Human-Readable Date
```bash
date -u -d "2024-01-15 14:30:00" +%Y-%m-%dT%H:%M:%SZ
```

#### Current Time
```bash
date -u +%Y-%m-%dT%H:%M:%SZ
```

## Troubleshooting

### Connection Error
```
Failed to connect to Scylla: gocql: unable to create session
```

**Solutions:**
- Verify Scylla nodes are running: `nodetool status`
- Check node IPs are correct
- Verify firewall allows port 9042
- Test with cqlsh: `cqlsh <node-ip>`

### No Data Returned
```
Total Calls: 0
```

**Possible causes:**
- No data in the specified time range
- Phone number doesn't exist
- Time range is in the future
- Data has expired (TTL)

**Solutions:**
- Verify data exists: `cqlsh -e "SELECT COUNT(*) FROM calldrop.call_records;"`
- Check time range is correct
- Verify phone number format

### Invalid Time Format
```
Error parsing start-time: parsing time "..." as "2006-01-02T15:04:05Z07:00"
```

**Solution:**
Use RFC3339 format: `2024-01-01T00:00:00Z`

### Module Not Found
```
call-success-rate.go:10:2: no required module provides package github.com/gocql/gocql
```

**Solution:**
```bash
go mod download
```

## Advanced Usage

### Custom Consistency Level
Edit the code to change consistency level:
```go
cluster.Consistency = gocql.One  // Faster, less consistent
cluster.Consistency = gocql.All  // Slower, most consistent
```

### Timeout Adjustment
```go
cluster.Timeout = 30 * time.Second  // Increase for slow queries
```

### Parallel Processing
For better performance with many users, implement parallel queries:
```go
// Use goroutines and channels for concurrent queries
```

## Integration with Other Tools

### Shell Script Wrapper
```bash
#!/bin/bash
# daily-report.sh

TODAY=$(date -u +%Y-%m-%dT00:00:00Z)
TOMORROW=$(date -u -d 'tomorrow' +%Y-%m-%dT00:00:00Z)

./call-success-rate \
  --nodes=$SCYLLA_NODES \
  --start-time=$TODAY \
  --end-time=$TOMORROW \
  > daily-report-$(date +%Y%m%d).txt
```

### Cron Job
```cron
# Run daily at midnight
0 0 * * * /path/to/daily-report.sh
```

### Monitoring Alert
Use the output to trigger alerts:
```bash
RATE=$(./call-success-rate ... | grep "Success Rate:" | awk '{print $3}' | tr -d '%')
if (( $(echo "$RATE < 80" | bc -l) )); then
    echo "Alert: Success rate below 80%: $RATE%"
fi
```

## Output Files

Save output to file:
```bash
go run call-success-rate.go \
  --start-time=2024-01-01T00:00:00Z \
  --end-time=2024-01-31T23:59:59Z \
  > ../outputs/january-2024-report.txt
```

## Testing

### Test with Sample Data
```bash
# Generate test data first
cd ../../data-model/generation-scripts
python3 generate-call-data.py

# Run analytics
cd ../../analytics/scripts
go run call-success-rate.go \
  --start-time=2024-01-01T00:00:00Z \
  --end-time=2024-12-31T23:59:59Z
```

### Verify Results
Compare with direct CQL query:
```sql
-- Total calls
SELECT COUNT(*) FROM calldrop.call_records;

-- Successful calls
SELECT COUNT(*) FROM calldrop.calls_by_completion WHERE call_completed = true;

-- Failed calls
SELECT COUNT(*) FROM calldrop.calls_by_completion WHERE call_completed = false;
```

## Next Steps

After running analytics:
1. Save output to `../outputs/` directory
2. Compare results before and after bulk data load
3. Analyze shard distribution in Grafana
4. Document findings in `../../documentation/`

## References

- [gocql Documentation](https://github.com/gocql/gocql)
- [Go Time Package](https://pkg.go.dev/time)
- [Scylla Go Driver](https://docs.scylladb.com/stable/using-scylla/drivers/cql-drivers/scylla-go-driver.html)