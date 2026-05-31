#!/bin/bash
# To make this file executable:
# chmod +x gen_keys.sh

# Then, to run this file:
# ./gen_keys.sh

for i in {1..10000}; do
    redis-cli -p 6379 INCR counter
done
