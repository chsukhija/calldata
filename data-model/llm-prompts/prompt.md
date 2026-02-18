# LLM Prompt for CallDrop Data Model

## Prompt Used

```
I need to design a data model for a telecommunications company called "CallDrop" that tracks call information in a ScyllaDB/Cassandra database.

Requirements:
1. The table should store call tracking information with the following columns:
   - User's phone number (partition key)
   - Destination number (clustering key)
   - Call timestamp (should be part of clustering key for time-based queries)
   - Call duration in seconds
   - Source cell tower ID
   - Destination cell tower ID
   - Call successfully completed (boolean - true/false)
   - Source phone IMEI number

2. Design considerations:
   - The partition key should be the user's phone number to group all calls by user
   - The clustering key should include destination number and timestamp to allow:
     * Queries for calls to specific destinations
     * Time-range queries for a user's calls
     * Ordering by most recent calls
   - We need to support queries for:
     * All calls from a specific user
     * Calls from a user to a specific destination
     * Calls within a time range
     * Successfully completed calls (via materialized view)

3. Additional requirements:
   - Create a materialized view to query by call completion status
   - The schema should be optimized for write-heavy workloads (typical for call records)
   - Consider TTL for data retention if needed
   - Include appropriate indexes if necessary

Please provide:
1. The complete CQL schema for the main table
2. The materialized view for querying by completion status
3. Any additional indexes or configurations recommended
4. Explanation of the design choices
5. Sample queries that would be efficient with this schema
6. Any potential issues or limitations to be aware of

The data will include approximately 15 users with 20-25 calls per user initially, but should scale to millions of records.
```

## LLM Used
- **Model**: Claude 3.5 Sonnet / ChatGPT-4 / Gemini Pro
- **Date**: [To be filled when actually used]
- **Purpose**: Generate optimized data model for telecommunications call tracking

## Context Provided
- Database: ScyllaDB (Cassandra-compatible)
- Use case: Telecommunications call tracking
- Scale: Starting with ~375-400 records, scaling to millions
- Query patterns: User-centric, time-based, completion status filtering
- Workload: Write-heavy with analytical read queries

## Expected Output
- CQL schema definitions
- Materialized view definitions
- Query examples
- Design rationale
- Performance considerations