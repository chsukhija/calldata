# CallDrop - Scylla Database Project

## Project Overview
This repository contains the complete implementation of a Scylla database cluster for CallDrop, a large Telco provider. The project includes cluster setup, data modeling, data generation, and analytics capabilities for tracking call information.

## Project Structure

```
calldata/
├── setup/
│   ├── scylla-installation/     # Scylla installation scripts and configs
│   └── monitoring/              # Monitoring stack setup
├── data-model/
│   ├── schema/                  # CQL schema definitions
│   ├── generation-scripts/      # Data generation scripts
│   └── llm-prompts/            # LLM prompts and outputs
├── analytics/
│   ├── scripts/                 # Analytics and query scripts
│   └── outputs/                 # Sample outputs
├── documentation/               # Detailed documentation for each task
├── monitoring-snapshots/        # Monitoring dashboard screenshots
└── outputs/                     # Task outputs (nodetool status, etc.)
```

## System Architecture

### Infrastructure
- **Cloud Provider**: AWS
- **Operating System**: Ubuntu
- **Scylla Nodes**: 3 nodes for the database cluster
- **Monitoring Node**: 1 node for Scylla monitoring stack
- **Client Node**: 1 node for running scripts and queries

### Cluster Configuration
- Scylla Open Source (latest version)
- Gossip protocol for AWS cloud provider
- Monitoring via Docker containers

## Tasks Completed

### Task 1: Cluster Setup
- ✅ Scylla installation on 3 nodes
- ✅ Monitoring stack installation
- ✅ Cluster configuration and verification
- 📁 Output: `outputs/task1/`

### Task 2: Data Model & Generation
- ✅ LLM-generated data model for call tracking
- ✅ Schema creation with partition and clustering keys
- ✅ Materialized view for successful calls
- ✅ Generated 15 users with 20-25 calls each
- 📁 Output: `data-model/` and `outputs/task2/`

### Task 3: Analytics Script
- ✅ Script to calculate call success rate
- ✅ Time range filtering
- ✅ Optional phone number filtering
- 📁 Output: `analytics/scripts/` and `analytics/outputs/`

### Task 4: Performance Analysis
- ✅ Shard imbalance analysis
- ✅ Written explanation of imbalance causes
- 📁 Output: `documentation/task4-shard-imbalance-analysis.md`

## Data Model

### Call Tracking Table
```cql
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
) WITH CLUSTERING ORDER BY (destination_number ASC, call_timestamp DESC);
```

### Materialized View
```cql
CREATE MATERIALIZED VIEW calldrop.calls_by_completion AS
    SELECT * FROM calldrop.call_records
    WHERE call_completed IS NOT NULL
    AND source_phone_number IS NOT NULL
    AND destination_number IS NOT NULL
    AND call_timestamp IS NOT NULL
    PRIMARY KEY (call_completed, source_phone_number, destination_number, call_timestamp);
```

## Quick Start

### Prerequisites
- SSH access to 4 AWS nodes (Ubuntu)
- Sudo privileges on all nodes
- Public/private SSH key pair

### Installation Steps

1. **Setup Scylla Cluster**
   ```bash
   cd setup/scylla-installation
   ./install-scylla.sh
   ```

2. **Setup Monitoring**
   ```bash
   cd setup/monitoring
   ./setup-monitoring.sh
   ```

3. **Create Schema**
   ```bash
   cd data-model/schema
   cqlsh -f create-schema.cql
   ```

4. **Generate Data**
   ```bash
   cd data-model/generation-scripts
   python3 generate-call-data.py
   ```

5. **Run Analytics**
   ```bash
   cd analytics/scripts
   go run call-success-rate.go --start-time "2024-01-01T00:00:00Z" --end-time "2024-01-01T23:59:59Z"
   ```

## Analytics Usage

### Calculate Call Success Rate
```bash
# For all users in a time range
go run call-success-rate.go \
  --start-time "2024-01-01T00:00:00Z" \
  --end-time "2024-01-01T23:59:59Z"

# For a specific phone number
go run call-success-rate.go \
  --start-time "2024-01-01T00:00:00Z" \
  --end-time "2024-01-01T23:59:59Z" \
  --phone-number "+1234567890"
```

## Key Deliverables

### Task 1 Outputs
- `outputs/task1/nodetool-status.txt` - Cluster status
- `monitoring-snapshots/` - Dashboard screenshots

### Task 2 Outputs
- `data-model/llm-prompts/prompt.md` - LLM prompt used
- `data-model/llm-prompts/llm-output.md` - LLM response
- `data-model/schema/` - Final schema files
- `outputs/task2/table-data-sample.txt` - Sample data output

### Task 3 Outputs
- `analytics/scripts/call-success-rate.go` - Analytics script
- `analytics/outputs/sample-output.txt` - Sample execution results

### Task 4 Outputs
- `documentation/task4-shard-imbalance-analysis.md` - Detailed analysis

## Technologies Used
- **Database**: ScyllaDB (Open Source)
- **Monitoring**: Scylla Monitoring Stack (Grafana + Prometheus)
- **Scripting**: Python 3, Golang, Bash
- **Data Generation**: Python with cassandra-driver
- **LLM**: Claude/ChatGPT/Gemini for data model design

## Notes
- All scripts are designed to be idempotent where possible
- Connection parameters are configurable via environment variables
- Monitoring dashboards accessible at http://<monitoring-node>:3000

## Contact
For questions or issues, please refer to the documentation in the `documentation/` directory.
