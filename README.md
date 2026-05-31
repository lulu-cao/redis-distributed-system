The exercises below are ordered so each one builds on the previous one and maps to concepts from *Designing Data-Intensive Applications*.

# Learning Goals

By the end, you'll have experienced:

* Replication
* Consistency vs availability
* Failover
* Leader election
* Network partitions
* Split brain
* Distributed locking
* Cache invalidation
* Eventual consistency
* Data loss
* CAP theorem tradeoffs

---

# Lab 0: Single Node Redis

## Setup

```yaml
# redis-compose.yml
services:
  redis:
    image: redis:7
    ports:
      - "6379:6379"
```

Start:

```bash
docker compose -f ./redis-compose.yml up
```

Connect:

```bash
redis-cli -p 6379
```

Write:

```bash
SET user "Alice"
GET user
```

## Lesson

This is **not** a distributed system.

Questions:

* What happens if this machine dies?
* What happens if the disk fails?
* How many copies exist?

Answer: one.

This establishes why distributed systems exist.

---

# Lab 1: Replication

## Setup

Add replica:

```yaml
services:
  primary:
    image: redis:7
    ports:
      - "6379:6379"

  replica:
    image: redis:7
    command: redis-server --replicaof primary 6379
    ports:
      - "6380:6379"
```

Start cluster.

---

## Exercise

Write to primary:

```bash
redis-cli -p 6379
SET counter 1
```

Read from replica:

```bash
redis-cli -p 6380
GET counter
```

---

## Lesson

You now have:

```text
Primary
   ↓
Replica
```

Benefits:

* redundancy
* read scaling

Costs:

* synchronization complexity

---

# Lab 2: Eventual Consistency

Generate lots of writes:

```bash
for i in {1..10000}; do
    redis-cli -p 6379 INCR counter
done
```

Pause replica:

```bash
docker pause replica
```

Wait 30 seconds.

Resume:

```bash
docker unpause replica
```

---

## Observe

Replica falls behind.

Eventually catches up.

This is eventual consistency.

---

## Lesson

Question:

Would you rather:

```text
Always correct
or
Always available
```

Many distributed systems choose differently.

---

# Lab 3: Redis Sentinel

Add three Sentinel nodes.

[Redis Sentinel Documentation](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/?utm_source=chatgpt.com)

Architecture:

```text
Primary
Replica

Sentinel1
Sentinel2
Sentinel3
```

---

## Exercise

Start cluster.

Observe monitoring in Docker container logs.

---

## Lesson

Sentinels form a quorum.

This introduces consensus.

---

# Lab 4: Automatic Failover

Stop primary:

```bash
docker stop primary
```

Watch Sentinel logs.

Eventually:

```text
Replica promoted
```

---

## Lesson

Questions:

* Who promoted it?
* How many votes were required?
* What if sentinels disagree?

This is distributed consensus.

---

# Lab 5: Quorum

Architecture:

```text
Sentinel1
Sentinel2
Sentinel3
```

Stop one:

```bash
docker stop sentinel3
```

Cluster still works.

Stop another.

Observe behavior.

---

## Lesson

Learn:

```text
3 nodes
Need 2 votes

5 nodes
Need 3 votes
```

This is quorum.

---

# Lab 6: Network Partition

Create:

```text
Primary ----X---- Replica
```

Use Docker network controls.

Disconnect replica:

```bash
docker network disconnect
```

Keep writing.

Reconnect.

Observe synchronization.

---

## Lesson

This is the classic CAP theorem scenario.

Question:

Should stale reads be allowed?

Different systems answer differently.

---

# Lab 7: Data Loss During Failover

Disconnect replica.

Write:

```bash
SET order123 paid
```

Before replication completes:

```bash
kill primary
```

Promote replica.

Check:

```bash
GET order123
```

Sometimes missing.

---

## Lesson

You discover a painful truth:

Replication is not the same as durability.

---

# Lab 8: Split Brain

Create conditions where:

```text
Primary thinks alive

Replica promoted elsewhere
```

Two primaries emerge.

Writes happen on both.

---

## Lesson

Now you have:

```text
Version A
Version B
```

Which is correct?

There may be no perfect answer.

---

# Lab 9: Distributed Locks

Use:

```bash
SET lock:job123 owner1 NX EX 30
```

Try from another client:

```bash
SET lock:job123 owner2 NX EX 30
```

Fails.

---

## Lesson

This prevents:

```text
Worker A processing order
Worker B processing same order
```

at the same time.

This is a primitive distributed coordination mechanism.

---

# Lab 10: Redlock Debate

Read about Redis Redlock:

[Redis Distributed Locks Pattern](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/?utm_source=chatgpt.com)

Then read criticisms from distributed-systems experts.

Questions:

* What is a lock?
* What is ownership?
* What happens during partitions?

This is one of the most famous distributed-systems debates.

---

# Lab 11: Build a Mini Distributed Application

Create:

```text
API Server A
API Server B
Redis Primary
Redis Replica
Sentinels
```

Features:

* user profiles
* counters
* locks

Then deliberately:

* kill nodes
* restart nodes
* partition networks

Observe behavior.

---

# Final Challenge

Build a simple ticket reservation system:

```text
100 tickets available
```

Requirements:

* no double booking
* survive node failures
* support concurrent users

Questions you'll encounter:

* Where should writes go?
* Can reads use replicas?
* How do you lock tickets?
* What happens during failover?
* Can data be lost?

By the time you finish this project, many of the abstract ideas from DDIA—replication, consensus, leader election, consistency, availability, and fault tolerance—stop being theoretical and become concrete engineering tradeoffs you've experienced firsthand.
