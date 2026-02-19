# Task 2 – CallDrop Data Model and Data Generation

## 1. Table Schema

Base Table: `call_records`

Columns:

- user_phone (Partition Key)
- call_success (Clustering Key)
- call_timestamp
- destination_number
- call_duration_seconds
- source_cell_tower_id
- destination_cell_tower_id
- source_phone_imei

Primary Key:
```
PRIMARY KEY ((user_phone), call_success, call_timestamp, destination_number)
```

Screenshot reference:
- `schema.png`
  
![alt text](schema.png)

## 2. Materialized View
Materialized View: `successful_calls`
```
CREATE MATERIALIZED VIEW successful_calls AS
SELECT *
FROM call_records
WHERE user_phone IS NOT NULL
AND call_success IS NOT NULL
AND call_timestamp IS NOT NULL
AND destination_number IS NOT NULL
PRIMARY KEY ((user_phone), call_success, call_timestamp, destination_number);
```

Purpose:
- Retrieve successfully completed calls efficiently.

Definition:

## 3. Data Generation
  
Link - [setupdata.sh](setupdata.sh)

Screenshot reference:
- `datageneration.png`
  
![alt text](datageneration.png)

![alt text](table.png)

## 4. Summary

✔ Schema created  
✔ Materialized view created  
✔ Data successfully inserted  
✔ Queries validated  
