#!/bin/bash

SCYLLA_NODE="172.31.31.48"
KEYSPACE="calldrop"

echo "Creating keyspace..."

cqlsh $SCYLLA_NODE <<EOF
CREATE KEYSPACE IF NOT EXISTS $KEYSPACE
WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'us-west-2': 3
};
EOF

echo "Creating table..."

cqlsh $SCYLLA_NODE <<EOF
USE $KEYSPACE;

DROP TABLE IF EXISTS call_records;

CREATE TABLE call_records (
    user_phone text,
    call_success boolean,
    call_timestamp timestamp,
    destination_number text,
    call_duration_seconds int,
    source_cell_tower_id text,
    destination_cell_tower_id text,
    source_phone_imei text,
    PRIMARY KEY ((user_phone), call_success, call_timestamp, destination_number)
) WITH CLUSTERING ORDER BY (call_success ASC, call_timestamp DESC, destination_number ASC);
EOF

echo "Creating materialized view..."

cqlsh $SCYLLA_NODE <<EOF
USE $KEYSPACE;

DROP MATERIALIZED VIEW IF EXISTS successful_calls;

CREATE MATERIALIZED VIEW successful_calls AS
SELECT *
FROM call_records
WHERE user_phone IS NOT NULL
  AND call_success IS NOT NULL
  AND call_timestamp IS NOT NULL
  AND destination_number IS NOT NULL
PRIMARY KEY ((user_phone), call_success, call_timestamp, destination_number);
EOF

echo "Inserting data..."

for i in {1..15}
do
  USER="+1555000$i"
  CALL_COUNT=$((20 + RANDOM % 6))

  for ((j=1; j<=CALL_COUNT; j++))
  do
    DEST="+1666$((100000 + RANDOM % 900000))"
    DURATION=$((10 + RANDOM % 1200))
    SRC_TOWER="TWR$((1 + RANDOM % 50))"
    DST_TOWER="TWR$((1 + RANDOM % 50))"
    SUCCESS=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")
    IMEI=$(uuidgen)
    TS=$(date -u -d "$((RANDOM % 72)) hours ago" +"%Y-%m-%d %H:%M:%S")

    cqlsh $SCYLLA_NODE -e "
    INSERT INTO $KEYSPACE.call_records (
      user_phone,
      call_success,
      call_timestamp,
      destination_number,
      call_duration_seconds,
      source_cell_tower_id,
      destination_cell_tower_id,
      source_phone_imei
    ) VALUES (
      '$USER',
      $SUCCESS,
      '$TS',
      '$DEST',
      $DURATION,
      '$SRC_TOWER',
      '$DST_TOWER',
      '$IMEI'
    );"
  done

  echo "Inserted $CALL_COUNT calls for $USER"
done

echo "Data load complete."
