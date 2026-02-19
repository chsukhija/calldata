# Load Script Execution Guide

This document explains how to execute `loadscript.py` to load CallDrop
data into the Scylla cluster.

------------------------------------------------------------------------

## 1. Prerequisites

-   Ubuntu 22.04 / 24.04
-   Python 3.12 installed
-   Access to Scylla cluster node (port 9042 open)
-   SSH access to client machine

Cluster target example: 172.31.31.48

------------------------------------------------------------------------

## 2. Install Python Virtual Environment Support

Ubuntu uses PEP 668 protection, so system-wide pip installs are blocked.

Install required packages:

sudo apt update sudo apt install python3.12-venv python3.12-full -y

------------------------------------------------------------------------

## 3. Create Virtual Environment

python3.12 -m venv venv

Activate it:

source venv/bin/activate

You should see: (venv) ubuntu@hostname:\~\$

------------------------------------------------------------------------

## 4. Install Required Python Dependencies

Inside the virtual environment:

pip install cassandra-driver

Verify installation:

python -c "from cassandra.cluster import Cluster; print('Driver
installed successfully')"

------------------------------------------------------------------------

## 5. Execute the Load Script

Run:

python loadscript.py

If successful, the script will: - Connect to Scylla cluster - Insert
generated CallDrop records - Print insertion progress

------------------------------------------------------------------------

## 6. Verify Data in Scylla

Connect using:

cqlsh 172.31.31.48

Check records:

USE calldrop; SELECT \* FROM call_records LIMIT 10;

Check successful calls:

SELECT \* FROM successful_calls WHERE user_phone = '+15550001' AND
call_success = true;

------------------------------------------------------------------------

## 7. Deactivate Virtual Environment

After execution:

deactivate

------------------------------------------------------------------------

## 8. Troubleshooting

### ModuleNotFoundError: cassandra

Make sure virtual environment is activated: source venv/bin/activate

### Connection Refused

Check: - Scylla is running - Port 9042 is open - Security groups allow
access

------------------------------------------------------------------------

## 9. Summary

✔ Virtual environment created\
✔ Cassandra driver installed\
✔ Script executed successfully\
✔ Data verified via cqlsh

Script execution completed successfully.
