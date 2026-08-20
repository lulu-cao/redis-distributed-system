
# Final Challenge - Build a Mini Distributed Application

Create:

```text
API Server A
API Server B
Redis Primary
Redis Replica
Sentinels
```

Architecture:

```
                    Client
                        │
                (random requests)
                        │
        ┌───────────────┴───────────────┐
        │                               │
  API Server A                   API Server B
        │                               │
        └───────────────┬───────────────┘
                        │
              Redis Primary
                    │
              Replication
                    │
              Redis Replica
                    │
        Sentinel 1  Sentinel 2  Sentinel 3
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

## Feature 1 — User Profiles

Create endpoints.

```
POST /users
```

Body:

```json
{
  "id": 1,
  "name": "Lulu"
}
```

Store:

```
user:1

{
    "name":"Lulu"
}
```

---

Retrieve:

```
GET /users/1
```

Questions to think about:

* Which Redis node should reads use?
* Should writes always go to the primary?
* What if the primary dies halfway through?

---

## Feature 2 — Page Views

Create:

```
POST /posts/42/view
```

Implementation:

```
INCR post:42:views
```

Now send 100 requests.

Observe:

```
views = 100
```

Easy.

Now make both API servers handle requests simultaneously.

Still works because Redis operations are atomic.

---

Now introduce failure.

Kill Redis.

What happens?

Do page views disappear?

Should your API return an error?

Should it retry?

This is your first taste of resilience.

---

## Feature 3 — Like Counter

Endpoint:

```
POST /posts/42/like
```

Implementation:

```
INCR post:42:likes
```

Now hammer it.

```
1000 concurrent requests
```

Observe:

```
likes = 1000
```

Redis atomic operations make this surprisingly easy.

---

Now intentionally make it wrong.

Instead of:

```
INCR
```

do

```
GET

value++

SET
```

Run 1000 requests.

Result:

```
943 likes
```

Where did 57 go?

You discovered race conditions.

---

## Feature 4 — Ticket Reservation

Suppose:

```
10 tickets
```

Users reserve tickets.

Naive implementation:

```
GET remaining

remaining--

SET remaining
```

Two requests arrive simultaneously.

Both read:

```
10
```

Both write:

```
9
```

You just oversold.

---

Fix it using:

```
SET lock:tickets NX EX 10
```

Only one server gets the lock.

Now reservations work.

---

Questions:

What if the server crashes while holding the lock?

Why does the lock expire?

Could another server start processing too early?

---

## Feature 5 — Background Jobs

Every API server runs:

```
cleanupExpiredSessions()
```

every minute.

Without coordination:

```
Server A deletes sessions

Server B deletes sessions
```

Duplicate work.

Introduce Redis lock.

Only one server performs cleanup.

This demonstrates distributed coordination.

---

## Feature 6 — Read Replicas

Reads:

```
GET /users/1
```

come from:

```
Redis Replica
```

Writes:

```
POST /users
```

go to:

```
Primary
```

---

Experiment:

```
Update name

Immediately fetch profile
```

Sometimes:

```
Old name
```

Why?

Replication delay.

Congratulations.

You've experienced eventual consistency.

---

# Failure Exercises

Now the fun begins.

---

## Exercise 1 — Kill API Server

```
docker stop api-a
```

Continue making requests.

Everything still works because:

```
API Server B
```

is alive.

Discuss:

Why run multiple application servers?

---

## Exercise 2 — Kill Redis Primary

```
docker stop redis-primary
```

Observe:

* writes fail
* or Sentinel promotes replica

Questions:

How long did failover take?

Did clients notice?

---

## Exercise 3 — Restart Primary

```
docker start redis-primary
```

Observe:

Is it primary again?

Or replica?

Why?

---

## Exercise 4 — Network Partition

Disconnect:

```
Redis Replica
```

from network.

Keep writing.

Reconnect.

Observe:

Replica catches up.

Discuss:

Could clients have seen stale data during the partition?

---

## Exercise 5 — Replica Reads

Disconnect replica.

Continue reading.

Eventually:

```
GET user
```

returns old data.

Why?

Replica stopped receiving updates.

---

## Exercise 6 — Lock Failure

Acquire lock.

Immediately:

```
kill API Server A
```

Questions:

Who releases the lock?

Answer:

Nobody.

Redis expiration saves us.

---

## Exercise 7 — Sentinel Failure

Stop:

```
Sentinel 3
```

Everything still works.

Stop:

```
Sentinel 2
```

Now kill primary.

Observe.

Discuss quorum.

---

## Exercise 8 — Hammer the Cluster

Write a script.

```
100 users

1000 likes

500 page views

100 reservations
```

While script runs:

```
kill Redis

restart Redis

kill API

restart API
```

Observe:

* errors
* retries
* data loss
* recovery

This is much closer to operating a production distributed system.

---

# Questions to Ask After Each Exercise

The goal isn't just to see something happen—it's to understand *why*. After each experiment, ask yourself:

1. **What was the source of truth?** Was it the primary Redis node, a replica, or something cached?
2. **Did I lose data?** If so, exactly which operations were lost and why?
3. **Could a user notice this?** Would they see an error, stale data, or inconsistent behavior?
4. **What assumptions did my code make?** Did it assume a server was always available or that a write was immediately visible everywhere?
5. **How would a production system handle this?** Would it retry, return an error, queue the work, or use a different architecture?

---

## What You'll Learn

By the end of this project, you'll have experienced many of the concepts from *Designing Data-Intensive Applications* in a concrete way:

| Concept              | Where you'll see it                                      |
| -------------------- | -------------------------------------------------------- |
| Replication          | Primary → Replica synchronization                        |
| Eventual consistency | Reading from replicas after writes                       |
| Race conditions      | Naive like counter and ticket reservation                |
| Atomic operations    | Using `INCR` instead of `GET`/`SET`                      |
| Distributed locks    | Ticket reservations and background jobs                  |
| High availability    | Two API servers continue serving traffic when one fails  |
| Leader election      | Sentinel promotes a new primary                          |
| Quorum               | Sentinel voting during failover                          |
| Network partitions   | Disconnecting the replica                                |
| Failover             | Killing the primary and observing recovery               |
| Data loss            | Writes that never reached the replica before failover    |
| Fault tolerance      | How the application behaves while components are failing |

The key realization is that **distributed systems aren't difficult because of the individual technologies**. Each piece—Express, Redis, Docker—is straightforward on its own. The complexity comes from **everything that can happen between them**: delays, crashes, duplicate requests, stale data, and conflicting updates. This project lets you observe those behaviors in a small, approachable environment before encountering them in large production systems.
