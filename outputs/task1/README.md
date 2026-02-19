# Task 1 – Cluster Setup and Monitoring

## 1. Architecture Overview

### Scylla Cluster Architecture

```mermaid
flowchart LR
    Client[Client Node<br>172.31.26.203] -->|CQL (9042)| DB1[Scylla DB Node 1<br>172.31.31.48]
    Client --> DB2[Scylla DB Node 2<br>172.31.23.41]
    Client --> DB3[Scylla DB Node 3<br>172.31.25.35]

    DB1 <--> DB2
    DB2 <--> DB3
    DB1 <--> DB3

## 1. Cluster Node Details

| Role        | Private IP     | Public IP        |
|------------|---------------|------------------|
| DB Node 1  | 172.31.31.48  | 18.237.255.85    |
| DB Node 2  | 172.31.23.41  | 54.187.5.170     |
| DB Node 3  | 172.31.25.35  | 35.91.75.139     |
| Monitoring | 172.31.22.30  | 35.91.232.28     |
| Client     | 172.31.26.203 | 54.191.169.70    |

---

## 2. Cluster Health Verification

The cluster health was validated using nodetool status

The output confirms:

- All nodes are in `UN` (Up/Normal) state
- Replication factor is properly configured
- No nodes are down or joining

Screenshot reference:
- `nodetool.png`
  
![alt text](nodetool.png)

---

## 3. Monitoring Setup

Scylla Monitoring Stack was deployed on the monitoring node 35.91.232.28. 

### Components Running:
- Prometheus
- Grafana
- Alertmanager

Grafana Dashboard Access: [Grafana URL](http://35.91.232.28:3000/)


### Dashboard Screenshots

The following dashboards confirm cluster metrics visibility:

- `grafana.png`
- `grafana1.png`
- `grafana2.png`

![alt text](grafana.png)
![alt text](grafana1.png)
![alt text](grafana2.png)

Metrics verified:
- CPU utilization
- Disk usage
- Read/Write throughput
- Latency
- Node status

---

## 4. Validation Summary

✔ 3-node Scylla cluster operational  
✔ Monitoring stack deployed  
✔ Grafana dashboards active  
✔ Cluster health verified  
