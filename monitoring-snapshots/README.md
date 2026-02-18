# Monitoring Snapshots

## Overview
This directory contains screenshots from the Scylla Monitoring Stack (Grafana) dashboards.

## How to Capture Screenshots

### Access Grafana
```
URL: http://35.91.232.28:3000
Username: admin
Password: <your-password>
```

### Required Screenshots

#### 1. Overview Dashboard
**File**: `overview-dashboard.png`
**Dashboard**: Scylla Overview
**Panels to Include**:
- Cluster status
- Total throughput (ops/sec)
- Read/Write latency (P95, P99)
- CPU usage per node
- Memory usage per node

#### 2. Detailed Metrics
**File**: `detailed-metrics.png`
**Dashboard**: Scylla Detailed
**Panels to Include**:
- Per-node detailed metrics
- Cache hit ratio
- Compaction activity
- SSTable count

#### 3. OS Metrics
**File**: `os-metrics.png`
**Dashboard**: Scylla OS Metrics
**Panels to Include**:
- CPU usage per core
- Memory usage
- Disk I/O
- Network traffic

#### 4. CQL Metrics
**File**: `cql-metrics.png`
**Dashboard**: Scylla CQL
**Panels to Include**:
- CQL query latency
- Query throughput
- Connection count
- Prepared statements

#### 5. Shard Distribution
**File**: `shard-distribution.png`
**Dashboard**: Scylla Detailed
**Panels to Include**:
- Per-shard CPU usage
- Per-shard memory usage
- Per-shard request distribution
- Shard imbalance indicators

#### 6. After Bulk Load
**File**: `after-bulk-load.png`
**Dashboard**: Scylla Overview
**Panels to Include**:
- Same as overview, but after bulk data load
- Shows impact of increased data volume

## Screenshot Guidelines

### Timing
1. **Baseline**: Capture after initial setup (empty cluster)
2. **After Sample Data**: Capture after generating 345 records
3. **After Bulk Load**: Capture after loading bulk data script
4. **During Load**: Capture while bulk load is running (optional)

### Quality
- Use full-screen browser mode
- Ensure all panels are visible
- Include time range in screenshot
- Capture at appropriate zoom level
- Save as PNG format

### Naming Convention
```
<dashboard-name>-<stage>-<timestamp>.png

Examples:
overview-baseline-20240115.png
overview-after-sample-data-20240115.png
overview-after-bulk-load-20240115.png
shard-distribution-imbalance-20240115.png
```

## Key Metrics to Document

### Before Bulk Load
- Total data size: ~50KB
- Throughput: Minimal
- Latency: < 5ms (P99)
- CPU: < 10%
- Shard distribution: Balanced

### After Bulk Load
- Total data size: ~XXX MB/GB
- Throughput: XXX ops/sec
- Latency: XX ms (P99)
- CPU: XX%
- Shard distribution: Imbalanced (document ratio)

## Analysis Points

### Shard Imbalance
Document the following from screenshots:
1. Which shards are hot (high CPU/memory)
2. Imbalance ratio (max/min)
3. Request distribution across shards
4. Memory distribution across shards

### Performance Impact
Document:
1. Latency increase (before vs after)
2. Throughput changes
3. Resource utilization
4. Bottlenecks identified

## Screenshot Checklist

- [ ] overview-dashboard.png
- [ ] detailed-metrics.png
- [ ] os-metrics.png
- [ ] cql-metrics.png
- [ ] shard-distribution.png
- [ ] after-bulk-load.png

## Notes

### Browser Recommendations
- Chrome/Firefox for best compatibility
- Disable browser extensions that might interfere
- Use incognito/private mode for clean screenshots

### Time Range Selection
- Use appropriate time range for each screenshot
- For baseline: Last 5 minutes
- For bulk load: Last 30 minutes or duration of load
- For analysis: Last 1 hour

### Dashboard Navigation
```
Grafana Home → Dashboards → Scylla Monitoring → [Select Dashboard]
```

## Placeholder Files

Since this is a documentation repository, actual screenshots should be captured during real implementation. For now, this directory contains:

- This README explaining what screenshots to capture
- Placeholder text files describing expected content

## When to Update

Update screenshots:
1. After initial cluster setup
2. After schema creation
3. After sample data generation
4. After bulk data load
5. When investigating issues
6. For final documentation

## References

- Grafana Documentation: https://grafana.com/docs/
- Scylla Monitoring: https://monitoring.docs.scylladb.com/
- Dashboard Guide: https://monitoring.docs.scylladb.com/stable/use-monitoring/advisor/
