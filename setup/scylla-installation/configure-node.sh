#!/bin/bash

# Script to configure a Scylla node with specific IP addresses
# Usage: ./configure-node.sh <this-node-ip> <seed-node-ip>

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <this-node-ip> <seed-node-ip>"
    echo "Example: $0 10.0.1.10 10.0.1.10"
    exit 1
fi

THIS_NODE_IP=$1
SEED_NODE_IP=$2

echo "Configuring Scylla node..."
echo "This node IP: $THIS_NODE_IP"
echo "Seed node IP: $SEED_NODE_IP"

# Backup original configuration if not already backed up
if [ ! -f /etc/scylla/scylla.yaml.original ]; then
    sudo cp /etc/scylla/scylla.yaml /etc/scylla/scylla.yaml.original
fi

# Update scylla.yaml configuration
sudo tee /etc/scylla/scylla.yaml > /dev/null << EOF
# Scylla Configuration for CallDrop Cluster
cluster_name: 'CallDrop-Cluster'
seeds: "$SEED_NODE_IP"
listen_address: $THIS_NODE_IP
rpc_address: $THIS_NODE_IP
broadcast_rpc_address: $THIS_NODE_IP
endpoint_snitch: Ec2Snitch

# Data directories
data_file_directories:
    - /var/lib/scylla/data

commitlog_directory: /var/lib/scylla/commitlog

# Performance settings
auto_bootstrap: true

# Enable native transport
start_native_transport: true
native_transport_port: 9042

# Storage port
storage_port: 7000
ssl_storage_port: 7001

# Enable JMX
api_port: 10000
api_address: $THIS_NODE_IP

# Prometheus port
prometheus_port: 9180
prometheus_address: $THIS_NODE_IP
EOF

echo "Configuration updated successfully!"
echo ""
echo "To start Scylla, run:"
echo "  sudo systemctl enable scylla-server"
echo "  sudo systemctl start scylla-server"
echo ""
echo "To check status:"
echo "  sudo systemctl status scylla-server"
echo "  nodetool status"

# Made with Bob
