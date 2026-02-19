# 📘 Call Success Rate Script

## 📌 Overview

The marketing team requires visibility into the percentage of
successfully completed phone calls within a specified time range.

This script calculates the **success rate of calls** stored in ScyllaDB
by:

-   Accepting a time range
-   Optionally filtering by a specific phone number
-   Returning the percentage of successfully completed calls

------------------------------------------------------------------------

## 🛠 Technology Used

-   Language: Bash\
-   Database: ScyllaDB\
-   Interface: cqlsh

------------------------------------------------------------------------

## 📥 Inputs

The script accepts:

1.  Start time
2.  End time
3.  Optional phone number

### Usage

``` bash
./success.sh 'YYYY-MM-DD HH:MM:SS' 'YYYY-MM-DD HH:MM:SS' [phone_number]
```

Script Link - [success.sh](success.sh)

------------------------------------------------------------------------

## 📌 Example Usage

### 🔹 Filter by specific phone number

``` bash
./success.sh '2026-02-11 00:00:00' '2026-02-17 00:00:00' '+15550006'
```

### 🔹 Query all users (no phone filter)

``` bash
./success.sh '2026-02-17 00:00:00' '2026-02-18 00:00:00'
```

------------------------------------------------------------------------

## 📤 Output

The script outputs:

-   Total calls in range
-   Number of successful calls
-   Percentage of successful calls

### Example Output

<img width="893" height="581" alt="success" src="https://github.com/user-attachments/assets/15298a79-7fe4-476b-9121-d82f4e0bb753" />


    Scylla Success Rate Report
    Time Range: 2026-02-17 00:00:00 → 2026-02-18 00:00:00

    Total Calls      : 120
    Successful Calls : 93
    Success Rate     : 77.50 %

------------------------------------------------------------------------

## ⚠ Design Considerations

Because `user_phone` is the partition key:

-   Queries filtering by phone are efficient.
-   Queries without a phone filter require ALLOW FILTERING, which scans
    across partitions.

For large-scale production systems, a separate time-based aggregation
table should be designed to avoid full partition scans.

------------------------------------------------------------------------

## 📊 Business Value

This script allows the marketing team to:

-   Measure call completion performance
-   Compare user-level success rates
-   Analyze system performance during specific time windows

------------------------------------------------------------------------

## ✅ Summary

✔ Accepts time range input\
✔ Optional phone filter\
✔ Calculates success percentage\
✔ Simple CLI-based solution\
✔ Scylla-compatible design

