#!/bin/bash

for i in {1..1000}; do
    redis-cli -p 6379 INCR counter
    sleep 0.5
done
