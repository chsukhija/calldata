#!/bin/bash

# Scylla Installation Script for Ubuntu on AWS
# This script installs the latest Scylla Open Source on Ubuntu nodes

set -e

echo "=========================================="
echo "Scylla Installation Script for CallDrop"
echo "=========================================="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Update system packages
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required dependencies
echo "Installing dependencies..."
apt-get install -y apt-transport-https wget gnupg2

# Add Scylla repository
echo "Adding Scylla repository..."
mkdir -p /etc/apt/keyrings
wget -O /etc/apt/keyrings/scylladb.asc https://downloads.scylladb.com/downloads/scylladb-keyring.asc

# Add Scylla repository for Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
echo "deb [signed-by=/etc/apt/keyrings/scylladb.asc] https://downloads.scylladb.com/downloads/scylla/deb/ubuntu/scylladb-6.2 $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/scylla.list

# Update package list
echo "Updating package list..."
apt-get update -y

# Install Scylla
echo "Installing Scylla..."
apt-get install -y scylla

# Run Scylla setup
echo "Running Scylla setup..."
scylla_setup

# Configure Scylla for AWS
echo "Configuring Scylla for AWS..."

# Backup original configuration
cp /etc/scylla/scylla.yaml /etc/scylla/scylla.yaml.backup

# Note: The following configurations should be customized per node
echo ""
echo "=========================================="
echo "IMPORTANT: Manual Configuration Required"
echo "=========================================="
echo ""
echo "Please edit /etc/scylla/scylla.yaml and configure:"
echo "1. cluster_name: 'CallDrop-Cluster'"
echo "2. seeds: '<seed-node-ip>'"
echo "3. listen_address: '<this-node-private-ip>'"
echo "4. rpc_address: '<this-node-private-ip>'"
echo "5. endpoint_snitch: Ec2Snitch"
echo "6. broadcast_rpc_address: '<this-node-private-ip>'"
echo ""
echo "For AWS, use Ec2Snitch as the endpoint_snitch"
echo ""
echo "After configuration, run:"
echo "  systemctl enable scylla-server"
echo "  systemctl start scylla-server"
echo ""
echo "Check status with:"
echo "  systemctl status scylla-server"
echo "  nodetool status"
echo ""

# Create a configuration template
cat > /etc/scylla/scylla.yaml.template << 'EOF'
# Scylla Configuration Template for CallDrop Cluster

# Cluster name - must be the same on all nodes
cluster_name: 'CallDrop-Cluster'

# Seeds - comma-separated list of seed node IPs
# Use private IPs of seed nodes (typically first node)
seeds: "SEED_NODE_IP"

# Listen address - private IP of this node
listen_address: THIS_NODE_PRIVATE_IP

# RPC address - private IP of this node
rpc_address: THIS_NODE_PRIVATE_IP

# Broadcast RPC address - private IP of this node
broadcast_rpc_address: THIS_NODE_PRIVATE_IP

# Endpoint snitch for AWS
endpoint_snitch: Ec2Snitch

# Data directories
data_file_directories:
    - /var/lib/scylla/data

# Commitlog directory
commitlog_directory: /var/lib/scylla/commitlog

# Enable authentication (optional, recommended for production)
# authenticator: PasswordAuthenticator
# authorizer: CassandraAuthorizer

# Other important settings
auto_bootstrap: true
EOF

echo "Configuration template created at /etc/scylla/scylla.yaml.template"
echo "Installation complete!"

# Made with Bob
