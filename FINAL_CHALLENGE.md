
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
            localhost:8080
                  │
            ┌───────────┐
            │   Nginx   │
            └─────┬─────┘
                  │
          Round Robin Routing
         ┌────────┴────────┐
         │                 │
    API Server A      API Server B
         │                 │
         └────────┬────────┘
                  │
            Redis Primary
                  │
            Redis Replica
```

Then deliberately:

* kill nodes
* restart nodes
* partition networks

Observe behavior.

# Failure Exercises

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

The key realization is that **distributed systems aren't difficult because of the individual technologies**. Each piece—NestJS, Redis, Docker—is straightforward on its own. The complexity comes from **everything that can happen between them**: delays, crashes, duplicate requests, stale data, and conflicting updates. This project lets you observe those behaviors in a small, approachable environment before encountering them in large production systems.

## Disclaimer 

The exercises are designed by ChatGPT. 