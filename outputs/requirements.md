## Preparation
I suggest completing S101: ScyllaDB Essentials – Overview of ScyllaDB and NoSQL Basics 

## Technical Task
Scenario and tasks: 
You are in the DevOps team at a large Telco provider named “CallDrop”. CallDrop would like to use Scylla. You are tasked to do the following: 



# 1
CallDrop is using AWS.

Download and Install the latest Scylla Open source on the 3 nodes provided to you.

The operating system you will be using is Ubuntu.

We provided you with a monitoring node, please install Scylla monitoring stack. 


# 2 
Once you have the Scylla cluster up and running, use an LLM of your choice (Gemini, Claude, ChatGPT) to create a data model for “CallDrop” call track information

The following will be our columns in the table: 

User’s phone number is used as partition key element 

Destination number is your clustering key 

Call duration in seconds

source cell tower id

destination cell tower id

call successfully completed (true/false)

source phone IMEI number 

Create ~15 users records, with 20-25 calls per user 

Create a materialized view for the successfully completed column.

Share with me the prompt, LLM output, schema, revisions and any final generation scripts you used.


# 3
The marketing team would like to know what the rate of calls successfully completed during a range of hours. 

Write in your preferred language (bash/*sh/python/java/C++/golang) a short script or program (no need for a UI) that receives the following input:

A range of time

Optionally, a phone number to filter by

The output will should be - 

Percentage of successfully completed phone calls


# 4
A script will be provided to you once you reach stage 3 (email me with the output from step 2). After receiving the script, execute it to load data. Rerun your script from step 3. Can you explain the imbalance in the monitoring dashboard between the different Shards in the nodes?

System to work with: 
Scylla will provide you with 4 nodes for your testing. 

a. Please create a public/private ssh key, and provide us with your public key part.

b. You have sudo rights on the nodes, you may install software as you see fit

c. Scylla should be downloaded from ScyllaDB.com (using the binary option. I.e. apt-get)

b. Use the appropriate Gossiping protocol for the cloud provider

c. Install Scylla monitoring using the docker container option on the 4th node

d. The fifth node will be your client node to run scripts

## Output
For item #1 Provide: 

 Nodetool status output 

 Monitoring snapshot's 

For item #2 Provide: 

Tables and keyspaces schema 

An output of the information in the table 

Prompt, LLM output, schema, revisions and any final generation scripts you used

For item #3 

Output of the summary and the code used to retrieve the information 

And a sample of the output based on the range scan criteria you selected. 

For item #4 

Written explanation of your understanding of the reason for imbalance
