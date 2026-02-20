# 📘 Data Load & Shard Imbalance Analysis

## 📌 Overview

At Stage 3, a data loading script is provided after submitting the
output from Step 2.\
This stage involves:

1.  Executing the provided script to load data into the cluster
2.  Rerunning the success-rate script from Step 3
3.  Analyzing shard imbalance observed in the monitoring dashboard

## 🚀 Step 1 -- Execute the Provided Load Script

After receiving the script (e.g., `loadscript.py`):

### 1️⃣ Create a Python virtual environment (recommended)

``` bash
python3 -m venv venv
source venv/bin/activate
pip install cassandra-driver
```

### 2️⃣ Run the load script

``` bash
python loadscript.py
```

This loads call data into the ScyllaDB cluster.


## 🔁 Step 2 -- Rerun Success Rate Script

After data load completes:

``` bash
./success.sh '2026-02-11 00:00:00' '2026-02-17 00:00:00' '+15550006'
```

This validates that the data was successfully inserted and calculates
call success percentage.


## 📊 Step 3 -- Analyze Shard Imbalance in Grafana

Open the Scylla Monitoring Dashboard in Grafana and navigate to:

-   Per-Shard CPU Usage
-   Writes per Shard
-   Reads per Shard
-   Reactor Utilization per Shard


## ⚠ Observed Shard Imbalance

In the monitoring dashboard, imbalance between shards may appear as:

-   Some shards showing high CPU utilization
-   Other shards remaining mostly idle
-   Uneven write distribution across shards

`Customer Dashboard using dashboard.json`
  
<img width="1721" height="945" alt="dash" src="https://github.com/user-attachments/assets/c90e0974-703a-4747-9395-16acadf4cac6" />


`Metric Explorer`

<img width="1707" height="863" alt="imb" src="https://github.com/user-attachments/assets/4a844ee8-0514-45cf-b482-59de009051a0" />


## 🧠 Explanation of Shard Imbalance

ScyllaDB uses a shared-nothing architecture where:

-   Each CPU core runs as an independent shard
-   Data is distributed based on token hashing of the partition key

Imbalance typically occurs due to:

### 1️⃣ Low Partition Cardinality

If only a small number of unique partition keys exist (e.g., few user
phone numbers), traffic may hash to only a subset of shards.

### 2️⃣ Hot Partitions

If certain phone numbers receive significantly more traffic, the shard
owning that token range becomes overloaded.

### 3️⃣ Non--Shard-Aware Driver

If the driver is not shard-aware, requests may not be optimally routed,
causing uneven load.

### 4️⃣ Sequential or Biased Data Generation

If the data loader inserts records with predictable or skewed partition
keys, token distribution becomes uneven.


## 🏗 Why This Happens in This Exercise

In this scenario:

-   Partition key = user_phone
-   Limited number of users (e.g., 15)
-   High number of writes per user

This results in a small number of partitions generating most of the
load, leading to visible shard imbalance.


## ✅ How to Improve Distribution

To reduce shard imbalance:

-   Increase partition key cardinality
-   Ensure random distribution of partition keys
-   Use a shard-aware driver
-   Validate token distribution using `nodetool status` and monitoring
    dashboards

## 📌 Summary

✔ Data load executed successfully\
✔ Success rate script rerun and validated\
✔ Shard imbalance observed and explained\
✔ Root cause identified as partition distribution pattern

This completes Stage 3 requirements.
