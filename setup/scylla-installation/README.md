# Scylla Installation Guide for CallDrop

## Overview
This directory contains scripts and documentation for installing Scylla Open Source on Ubuntu nodes in AWS.

## Prerequisites
- 3 Ubuntu nodes on AWS
- SSH access with sudo privileges
- Public/private SSH key pair

## Installation Steps

### Step 1: Prepare SSH Keys
Generate SSH key pair if you don't have one:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Share your public key (`~/.ssh/id_rsa.pub`) with the Scylla team to get access to the nodes.

### Step 2: Install Scylla on All 3 Nodes

On each node, run:
```bash
# Copy the installation script to the node
scp install-scylla.sh ubuntu@<node-ip>:~/

# SSH into the node
ssh ubuntu@<node-ip>

# Make the script executable and run it
chmod +x install-scylla.sh
sudo ./install-scylla.sh
```

### Step 3: Configure Each Node

Determine your node IPs:
- Node 1 (Seed): `<node1-ip>`
- Node 2: `<node2-ip>`
- Node 3: `<node3-ip>`

**On Node 1 (Seed Node):**
```bash
# Copy configuration script
scp configure-node.sh ubuntu@<node1-ip>:~/

# SSH and configure
ssh ubuntu@<node1-ip>
chmod +x configure-node.sh
sudo ./configure-node.sh <node1-ip> <node1-ip>

# Start Scylla
sudo systemctl enable scylla-server
sudo systemctl start scylla-server

# Wait for node to be up (check logs)
sudo journalctl -u scylla-server -f
```

**On Node 2:**
```bash
scp configure-node.sh ubuntu@<node2-ip>:~/
ssh ubuntu@<node2-ip>
chmod +x configure-node.sh
sudo ./configure-node.sh <node2-ip> <node1-ip>
sudo systemctl enable scylla-server
sudo systemctl start scylla-server
```

**On Node 3:**
```bash
scp configure-node.sh ubuntu@<node3-ip>:~/
ssh ubuntu@<node3-ip>
chmod +x configure-node.sh
sudo ./configure-node.sh <node3-ip> <node1-ip>
sudo systemctl enable scylla-server
sudo systemctl start scylla-server
```

### Step 4: Verify Cluster Status

On any node, run:
```bash
nodetool status
```

Expected output:
```
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address      Load       Tokens       Owns    Host ID                               Rack
UN  <node1-ip>   XXX KB     256          XX.X%   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  rack1
UN  <node2-ip>   XXX KB     256          XX.X%   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  rack1
UN  <node3-ip>   XXX KB     256          XX.X%   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  rack1
```

All nodes should show status `UN` (Up/Normal).

### Step 5: Test Connection

```bash
cqlsh <node1-ip>
```

You should see:
```
Connected to CallDrop-Cluster at <node1-ip>:9042.
[cqlsh 5.0.1 | Cassandra 3.0.8 | CQL spec 3.3.1 | Native protocol v4]
Use HELP for help.
cqlsh>
```

## Configuration Files

### scylla.yaml Key Settings
- **cluster_name**: `CallDrop-Cluster`
- **seeds**: IP of the first node (seed node)
- **listen_address**: Private IP of the current node
- **rpc_address**: Private IP of the current node
- **endpoint_snitch**: `Ec2Snitch` (for AWS)
- **broadcast_rpc_address**: Private IP of the current node

## Troubleshooting

### Check Scylla Service Status
```bash
sudo systemctl status scylla-server
```

### View Scylla Logs
```bash
sudo journalctl -u scylla-server -f
```

### Check Scylla Configuration
```bash
cat /etc/scylla/scylla.yaml
```

### Restart Scylla
```bash
sudo systemctl restart scylla-server
```

### Common Issues

**Issue**: Node not joining cluster
- Verify seed IP is correct in scylla.yaml
- Check firewall rules (ports 7000, 7001, 9042, 9160, 10000)
- Ensure all nodes can communicate with each other

**Issue**: Service fails to start
- Check logs: `sudo journalctl -u scylla-server -n 100`
- Verify disk space: `df -h`
- Check configuration syntax: `scylla --help`

## Security Considerations

For production:
1. Enable authentication:
   ```yaml
   authenticator: PasswordAuthenticator
   authorizer: CassandraAuthorizer
   ```

2. Configure SSL/TLS for client and inter-node communication

3. Set up proper firewall rules

4. Use security groups in AWS to restrict access

## Next Steps

After successful installation:
1. Set up Scylla Monitoring Stack (see `../monitoring/`)
2. Create keyspace and tables (see `../../data-model/schema/`)
3. Load data (see `../../data-model/generation-scripts/`)

## Files in This Directory

- `install-scylla.sh` - Main installation script
- `configure-node.sh` - Node configuration script
- `README.md` - This file

## References

- [Scylla Documentation](https://docs.scylladb.com/)
- [Scylla on AWS](https://docs.scylladb.com/stable/operating-scylla/procedures/cluster-management/create-cluster-aws.html)
- [Scylla Configuration](https://docs.scylladb.com/stable/operating-scylla/scylla-yaml.html)