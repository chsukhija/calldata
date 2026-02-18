#!/usr/bin/env python3
"""
CallDrop Data Generation Script
Generates sample call records for 15 users with 20-25 calls each
"""

import random
import sys
from datetime import datetime, timedelta
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
from cassandra.query import BatchStatement, ConsistencyLevel

# Configuration
SCYLLA_NODES = ['127.0.0.1']  # Update with your Scylla node IPs
KEYSPACE = 'calldrop'
NUM_USERS = 15
MIN_CALLS_PER_USER = 20
MAX_CALLS_PER_USER = 25

# Sample data pools
AREA_CODES = ['+1234', '+1235', '+1236', '+1237', '+1238']
CELL_TOWERS = [f'TOWER-{str(i).zfill(3)}' for i in range(1, 101)]

def generate_phone_number(area_code):
    """Generate a random phone number with given area code"""
    return f"{area_code}{random.randint(1000000, 9999999)}"

def generate_imei():
    """Generate a random IMEI number"""
    return ''.join([str(random.randint(0, 9)) for _ in range(15)])

def generate_users(num_users):
    """Generate list of user phone numbers"""
    users = []
    for _ in range(num_users):
        area_code = random.choice(AREA_CODES)
        phone = generate_phone_number(area_code)
        users.append(phone)
    return users

def generate_call_record(source_phone, base_time):
    """Generate a single call record"""
    # Random time offset (within last 30 days)
    time_offset = timedelta(
        days=random.randint(0, 29),
        hours=random.randint(0, 23),
        minutes=random.randint(0, 59),
        seconds=random.randint(0, 59)
    )
    call_timestamp = base_time - time_offset
    
    # Generate destination number (different from source)
    dest_area_code = random.choice(AREA_CODES)
    destination_number = generate_phone_number(dest_area_code)
    
    # Call duration (0-3600 seconds, with some failed calls having 0 duration)
    call_completed = random.random() > 0.15  # 85% success rate
    if call_completed:
        call_duration = random.randint(10, 3600)
    else:
        call_duration = random.randint(0, 30)  # Failed calls are short
    
    # Cell towers
    source_tower = random.choice(CELL_TOWERS)
    dest_tower = random.choice(CELL_TOWERS)
    
    # IMEI
    imei = generate_imei()
    
    return {
        'source_phone_number': source_phone,
        'destination_number': destination_number,
        'call_timestamp': call_timestamp,
        'call_duration_seconds': call_duration,
        'source_cell_tower_id': source_tower,
        'destination_cell_tower_id': dest_tower,
        'call_completed': call_completed,
        'source_phone_imei': imei
    }

def insert_call_records(session, records):
    """Insert call records into Scylla"""
    insert_query = """
        INSERT INTO call_records (
            source_phone_number,
            destination_number,
            call_timestamp,
            call_duration_seconds,
            source_cell_tower_id,
            destination_cell_tower_id,
            call_completed,
            source_phone_imei
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    prepared = session.prepare(insert_query)
    
    # Use batch for better performance
    batch_size = 50
    total_inserted = 0
    
    for i in range(0, len(records), batch_size):
        batch = BatchStatement(consistency_level=ConsistencyLevel.QUORUM)
        batch_records = records[i:i + batch_size]
        
        for record in batch_records:
            batch.add(prepared, (
                record['source_phone_number'],
                record['destination_number'],
                record['call_timestamp'],
                record['call_duration_seconds'],
                record['source_cell_tower_id'],
                record['destination_cell_tower_id'],
                record['call_completed'],
                record['source_phone_imei']
            ))
        
        session.execute(batch)
        total_inserted += len(batch_records)
        print(f"Inserted {total_inserted}/{len(records)} records...", end='\r')
    
    print(f"\nTotal records inserted: {total_inserted}")

def main():
    """Main function"""
    print("=" * 60)
    print("CallDrop Data Generation Script")
    print("=" * 60)
    
    # Parse command line arguments for node IPs
    if len(sys.argv) > 1:
        global SCYLLA_NODES
        SCYLLA_NODES = sys.argv[1].split(',')
    
    print(f"\nConfiguration:")
    print(f"  Scylla Nodes: {', '.join(SCYLLA_NODES)}")
    print(f"  Keyspace: {KEYSPACE}")
    print(f"  Number of Users: {NUM_USERS}")
    print(f"  Calls per User: {MIN_CALLS_PER_USER}-{MAX_CALLS_PER_USER}")
    print()
    
    # Connect to Scylla
    print("Connecting to Scylla cluster...")
    try:
        cluster = Cluster(SCYLLA_NODES)
        session = cluster.connect()
        session.set_keyspace(KEYSPACE)
        print("✓ Connected successfully")
    except Exception as e:
        print(f"✗ Failed to connect: {e}")
        sys.exit(1)
    
    # Generate users
    print(f"\nGenerating {NUM_USERS} users...")
    users = generate_users(NUM_USERS)
    print("✓ Users generated")
    print(f"  Sample users: {users[:3]}")
    
    # Generate call records
    print(f"\nGenerating call records...")
    base_time = datetime.now()
    all_records = []
    
    for user in users:
        num_calls = random.randint(MIN_CALLS_PER_USER, MAX_CALLS_PER_USER)
        for _ in range(num_calls):
            record = generate_call_record(user, base_time)
            all_records.append(record)
    
    print(f"✓ Generated {len(all_records)} call records")
    
    # Insert records
    print(f"\nInserting records into Scylla...")
    try:
        insert_call_records(session, all_records)
        print("✓ All records inserted successfully")
    except Exception as e:
        print(f"✗ Failed to insert records: {e}")
        sys.exit(1)
    
    # Verify insertion
    print(f"\nVerifying data...")
    count_query = "SELECT COUNT(*) FROM call_records"
    result = session.execute(count_query)
    count = result.one()[0]
    print(f"✓ Total records in database: {count}")
    
    # Show sample data
    print(f"\nSample records:")
    sample_query = f"SELECT * FROM call_records WHERE source_phone_number = '{users[0]}' LIMIT 5"
    results = session.execute(sample_query)
    
    print(f"\nCalls from {users[0]}:")
    print("-" * 100)
    for row in results:
        status = "✓" if row.call_completed else "✗"
        print(f"{status} To: {row.destination_number} | "
              f"Time: {row.call_timestamp} | "
              f"Duration: {row.call_duration_seconds}s | "
              f"Towers: {row.source_cell_tower_id} -> {row.destination_cell_tower_id}")
    
    # Statistics
    print(f"\nStatistics:")
    success_query = "SELECT COUNT(*) FROM calls_by_completion WHERE call_completed = true"
    failed_query = "SELECT COUNT(*) FROM calls_by_completion WHERE call_completed = false"
    
    success_count = session.execute(success_query).one()[0]
    failed_count = session.execute(failed_query).one()[0]
    total = success_count + failed_count
    
    if total > 0:
        success_rate = (success_count / total) * 100
        print(f"  Total Calls: {total}")
        print(f"  Successful: {success_count} ({success_rate:.1f}%)")
        print(f"  Failed: {failed_count} ({100-success_rate:.1f}%)")
    
    # Close connection
    cluster.shutdown()
    
    print("\n" + "=" * 60)
    print("Data generation complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()

# Made with Bob
