# Scylla Monitoring Stack Setup

## Overview
This directory contains scripts and configuration for setting up the Scylla Monitoring Stack using Docker containers on a dedicated monitoring node.

## Prerequisites
- Ubuntu monitoring node on AWS
- SSH access with sudo privileges
- Scylla cluster already running (3 nodes)

## Architecture
The monitoring stack consists of:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert management (optional)

## Installation Steps

### Step 1: Install Monitoring Stack

Copy the setup script to the monitoring node:
```bash
scp setup-monitoring.sh ubuntu@<monitoring-node-ip>:~/
```

SSH into the monitoring node and run:
```bash
ssh ubuntu@<monitoring-node-ip>
chmod +x setup-monitoring.sh
sudo ./setup-monitoring.sh
```

This script will:
- Install Docker and Docker Compose
- Clone the Scylla Monitoring Stack repository
- Set up the monitoring environment

### Step 2: Configure Scylla Nodes

Create the Prometheus configuration file with your Scylla node IPs:

```bash
cd /opt/scylla-monitoring
sudo nano prometheus/scylla_servers.yml
```

Add your node configuration:
```yaml
- targets:
  - <node1-ip>:9180
  - <node2-ip>:9180
  - <node3-ip>:9180
  labels:
    cluster: CallDrop-Cluster
    dc: datacenter1
```

Example with actual IPs:
```yaml
- targets:
  - 10.0.1.10:9180
  - 10.0.1.11:9180
  - 10.0.1.12:9180
  labels:
    cluster: CallDrop-Cluster
    dc: datacenter1
```

### Step 3: Start Monitoring Stack

```bash
cd /opt/scylla-monitoring
sudo ./start-all.sh -d /var/lib/scylla-monitoring
```

The `-d` flag specifies the data directory for Prometheus.

### Step 4: Verify Installation

Check that all containers are running:
```bash
sudo docker ps
```

You should see containers for:
- Prometheus
- Grafana
- Alertmanager (optional)

### Step 5: Access Grafana

Open your browser and navigate to:
```
http://<monitoring-node-ip>:3000
```

**Default credentials:**
- Username: `admin`
- Password: `admin`

You'll be prompted to change the password on first login.

## Available Dashboards

Once logged in to Grafana, you'll have access to several pre-configured dashboards:

1. **Scylla Overview**: High-level cluster metrics
2. **Scylla Detailed**: Detailed node and table metrics
3. **Scylla OS Metrics**: Operating system metrics
4. **Scylla CQL**: CQL query metrics
5. **Scylla Errors**: Error tracking and alerts

## Key Metrics to Monitor

### Cluster Health
- Node status (Up/Down)
- CPU usage per node
- Memory usage per node
- Disk I/O

### Performance
- Read/Write latency (P95, P99)
- Throughput (ops/sec)
- Cache hit ratio
- Compaction activity

### Shard Metrics
- Per-shard CPU usage
- Per-shard memory usage
- Per-shard request distribution
- Shard imbalance indicators

## Stopping the Monitoring Stack

```bash
cd /opt/scylla-monitoring
sudo ./kill-all.sh
```

## Restarting the Monitoring Stack

```bash
cd /opt/scylla-monitoring
sudo ./start-all.sh -d /var/lib/scylla-monitoring
```

## Taking Screenshots

For documentation purposes, take screenshots of:

1. **Overview Dashboard**
   - Navigate to Scylla Overview dashboard
   - Take full-page screenshot

2. **Detailed Metrics**
   - Navigate to Scylla Detailed dashboard
   - Capture key metrics panels

3. **Shard Distribution**
   - Look for shard-related panels
   - Capture any imbalance indicators

Save screenshots to: `../../monitoring-snapshots/`

## Troubleshooting

### Containers Not Starting

Check Docker logs:
```bash
sudo docker logs <container-name>
```

List all containers:
```bash
sudo docker ps -a
```

### Cannot Access Grafana

1. Check if Grafana container is running:
   ```bash
   sudo docker ps | grep grafana
   ```

2. Check firewall rules:
   ```bash
   sudo ufw status
   ```

3. Ensure port 3000 is open in AWS Security Group

### No Data in Dashboards

1. Verify Prometheus targets:
   - Navigate to `http://<monitoring-node-ip>:9090/targets`
   - All Scylla nodes should show as "UP"

2. Check Scylla node connectivity:
   ```bash
   curl http://<node-ip>:9180/metrics
   ```

3. Verify scylla_servers.yml configuration:
   ```bash
   cat /opt/scylla-monitoring/prometheus/scylla_servers.yml
   ```

### Prometheus Storage Issues

If Prometheus runs out of space:
```bash
# Check disk usage
df -h /var/lib/scylla-monitoring

# Clean old data (if needed)
sudo rm -rf /var/lib/scylla-monitoring/prometheus/*
```

## Configuration Files

### prometheus/scylla_servers.yml
Defines Scylla nodes to monitor.

### prometheus/prometheus.yml.template
Prometheus configuration template (auto-generated).

### grafana/provisioning/
Grafana datasources and dashboard configurations.

## Ports Used

- **3000**: Grafana web interface
- **9090**: Prometheus web interface
- **9093**: Alertmanager (if enabled)
- **9180**: Scylla Prometheus exporter (on each Scylla node)

## Security Considerations

For production:

1. **Change default passwords**
   - Grafana admin password
   - Add authentication to Prometheus

2. **Enable HTTPS**
   - Configure SSL/TLS for Grafana
   - Use reverse proxy (nginx/Apache)

3. **Restrict access**
   - Use AWS Security Groups
   - Configure firewall rules
   - VPN access only

4. **Set up alerts**
   - Configure Alertmanager
   - Set up notification channels (email, Slack, PagerDuty)

## Updating the Monitoring Stack

```bash
cd /opt/scylla-monitoring
sudo ./kill-all.sh
git pull
sudo ./start-all.sh -d /var/lib/scylla-monitoring
```

## Backup and Restore

### Backup Grafana Dashboards
```bash
sudo docker exec -it <grafana-container> grafana-cli admin export-dashboard
```

### Backup Prometheus Data
```bash
sudo tar -czf prometheus-backup.tar.gz /var/lib/scylla-monitoring/prometheus/
```

## Advanced Configuration

### Custom Retention Period

Edit the start command to change Prometheus retention:
```bash
sudo ./start-all.sh -d /var/lib/scylla-monitoring -r 30d
```

### External Alertmanager

Configure external Alertmanager in `prometheus/prometheus.yml.template`.

## Files in This Directory

- `setup-monitoring.sh` - Main setup script
- `scylla_servers.yml.example` - Example Prometheus targets configuration
- `README.md` - This file

## Next Steps

After monitoring is set up:
1. Verify all nodes are being monitored
2. Take baseline screenshots
3. Proceed with data model creation (see `../../data-model/`)

## References

- [Scylla Monitoring Stack Documentation](https://monitoring.docs.scylladb.com/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)