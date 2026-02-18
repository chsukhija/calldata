#!/bin/bash

# Scylla Monitoring Stack Setup Script
# This script installs Scylla Monitoring Stack using Docker on Ubuntu

set -e

echo "=========================================="
echo "Scylla Monitoring Stack Setup"
echo "=========================================="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Update system
echo "Updating system packages..."
apt-get update -y

# Install Docker
echo "Installing Docker..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add Docker repository
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package database with Docker packages
apt-get update -y

# Install Docker CE
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.24.0"
curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installations
echo "Verifying installations..."
docker --version
docker-compose --version

# Clone Scylla Monitoring Stack
echo "Cloning Scylla Monitoring Stack..."
cd /opt
if [ -d "scylla-monitoring" ]; then
    echo "Scylla monitoring directory already exists, removing..."
    rm -rf scylla-monitoring
fi

git clone https://github.com/scylladb/scylla-monitoring.git
cd scylla-monitoring

# Checkout latest stable version
git checkout master

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit prometheus/scylla_servers.yml with your Scylla node IPs"
echo "2. Run: cd /opt/scylla-monitoring && ./start-all.sh -d <data-dir>"
echo ""
echo "Example scylla_servers.yml:"
echo "---"
echo "- targets:"
echo "  - <node1-ip>:9180"
echo "  - <node2-ip>:9180"
echo "  - <node3-ip>:9180"
echo "  labels:"
echo "    cluster: CallDrop-Cluster"
echo "    dc: datacenter1"
echo ""
echo "Access Grafana at: http://<monitoring-node-ip>:3000"
echo "Default credentials: admin/admin"
echo ""

# Made with Bob
