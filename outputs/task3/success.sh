#!/bin/bash

SCYLLA_NODE="172.31.31.48"
KEYSPACE="calldrop"
TABLE="call_records"

# -------------------------------
# Inputs
# -------------------------------
START="$1"
END="$2"
PHONE="$3"

if [ -z "$START" ] || [ -z "$END" ]; then
  echo "Usage:"
  echo "  ./success.sh 'YYYY-MM-DD HH:MM:SS' 'YYYY-MM-DD HH:MM:SS' [phone_number]"
  exit 1
fi

echo "---------------------------------------------"
echo "Scylla Success Rate Report"
echo "Time Range: $START  →  $END"
echo "---------------------------------------------"

# -------------------------------
# Build Query
# -------------------------------

if [ -z "$PHONE" ]; then
  echo "Phone filter: ALL USERS"
  echo "WARNING: This will scan across partitions (ALLOW FILTERING)."

  QUERY="SELECT call_success FROM $KEYSPACE.$TABLE
         WHERE call_timestamp >= '$START'
           AND call_timestamp <= '$END'
         ALLOW FILTERING;"

else
  echo "Phone filter: $PHONE"

  QUERY="SELECT call_success FROM $KEYSPACE.$TABLE
         WHERE user_phone = '$PHONE'
           AND call_timestamp >= '$START'
           AND call_timestamp <= '$END'
         ALLOW FILTERING;"
fi

# -------------------------------
# Execute Query
# -------------------------------

RESULT=$(cqlsh $SCYLLA_NODE -e "$QUERY")

# Count total calls
TOTAL=$(echo "$RESULT" | grep -Ei "true|false" | wc -l)

# Count successful calls
SUCCESS=$(echo "$RESULT" | grep -i "true" | wc -l)

# -------------------------------
# Output Results
# -------------------------------

if [ "$TOTAL" -eq 0 ]; then
  echo ""
  echo "No calls found in the specified range."
  exit 0
fi

PERCENT=$(echo "scale=2; ($SUCCESS/$TOTAL)*100" | bc)

echo ""
echo "Total Calls      : $TOTAL"
echo "Successful Calls : $SUCCESS"
echo "Success Rate     : $PERCENT %"
echo "---------------------------------------------"
