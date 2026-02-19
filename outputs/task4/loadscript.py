#! /usr/bin/env python

# -*- coding: latin-1 -*-
#

### Using elasticsearch-py ###
import csv
from cassandra.cluster import Cluster
import time
import datetime
import random
import argparse
import concurrent.futures
from cassandra import ConsistencyLevel
from cassandra.concurrent import execute_concurrent_with_args


## Script args and Help
parser = argparse.ArgumentParser(add_help=True)

parser.add_argument('-s', action="store", dest="SCYLLA_IP", default="127.0.0.1")
opts = parser.parse_args()

SCYLLA_IP = opts.SCYLLA_IP.split(',')
print (SCYLLA_IP)

## Define KS + Table
create_ks = "CREATE KEYSPACE IF NOT EXISTS usractivity WITH replication = {'class' : 'SimpleStrategy', 'replication_factor' : 3};"
create_t1 = "CREATE TABLE IF NOT EXISTS usractivity.actions (ssn text, imei text, os text,  phonenum text, balance float, pdate date, PRIMARY KEY (ssn, imei));"
def strTimeProp(start, end, format, prop):
    stime = time.mktime(time.strptime(start, format))
    etime = time.mktime(time.strptime(end, format))
    ptime = stime + prop * (etime - stime)
    return time.strftime(format, time.localtime(ptime))

def randomDate(start, end, prop):
    return strTimeProp(start, end, '%Y-%m-%d', prop)


## Insert the data
def insert_data():
    ## Connect to Scylla cluster and create schema
    # session = cassandra.cluster.Cluster(SCYLLA_IP).connect()
    print("")
    print("## Connecting to Scylla cluster -> Creating schema")
    now = datetime.datetime.now()
    print now.strftime("%Y-%m-%d %H:%M:%S")
    session = Cluster(SCYLLA_IP).connect()
    session.execute(create_ks)
    session.execute(create_t1)

  ## Prepared CQL statement
    print("")
    print("## Preparing CQL statement")
    cql = "INSERT INTO usractivity.actions (ssn, imei, os, phonenum, balance, pdate) VALUES (?,?,?,?,?,?) using TIMESTAMP ?"
    cql_prepared = session.prepare(cql)
    cql_prepared.consistency_level = ConsistencyLevel.ONE
    print("")

    ssn1= [str(random.randint(100,999)),str(random.randint(10,99)),str(random.randint(1000,9999))]
    tmpssn= '-'.join(ssn1)
    phone1= [str(random.randint(200,999)),str(random.randint(100,999)),str(random.randint(1000,9999))]
    phone= '-'.join(phone1)
    imei = str(random.randint(100000000000000,999999999999999))
    os1 =['Android','iOS','Windows','Samsung','Nokia']
    os = random.choice(os1)
    bal= round(random.uniform(10.5,999.5),2)
    dat= randomDate("2019-01-01", "2019-04-01", random.random())
    i=0
    counter=0
    while i<10000000 :
        if (i % 500000 == 0) :
                now = datetime.datetime.now()
                print ("inserted records:", i, now.strftime("%Y-%m-%d %H:%M:%S"))
        ssn1= [str(random.randint(100,999)),str(random.randint(10,99)),str(random.randint(1000,9999))]
        ssn= '-'.join(ssn1)
        if i == 50 :
           ssn=tmpssn
           counter+=1
           i=49
           if counter>100000 :
                i=51
        imei = str(random.randint(100000000000000,999999999999999))
        os1 =['Android','iOS','Windows','Samsung','Nokia']
        os = random.choice(os1)
        phone1= [str(random.randint(200,999)),str(random.randint(100,999)),str(random.randint(1000,9999))]
        phone= '-'.join(phone1)
        bal= round(random.uniform(10.5,999.5),2)
        dat= randomDate("2019-01-01", "2019-04-01", random.random())
        i+=1

        session.execute(cql_prepared, (ssn,imei,os,phone,bal,dat))

if __name__ == "__main__":
    insert_data()
    now = datetime.datetime.now()
    print now.strftime("%Y-%m-%d %H:%M:%S")
