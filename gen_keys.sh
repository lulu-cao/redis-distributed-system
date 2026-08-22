#!/bin/bash
# To make this file executable:
# chmod +x gen_keys.sh

# Then, to run this file:
# ./gen_keys.sh

# Increment counter to simulate incoming requests to redis
for i in {1..10000}; do
    redis-cli -p 6380 INCR counter
done

# creates a distributed lock and monitors its expiration time
SET lock:job123 owner2 NX EX 10
while true; do redis-cli TTL lock:job123; sleep 1; done
