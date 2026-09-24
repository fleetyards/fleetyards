# Redis Eviction Policy and Sidekiq

**Date:** 2026-09-24 (research during the Redis 7.2 → 8.2 upgrade, #4334 / #4335)

Production runs one Redis instance for Sidekiq, the Rails cache, sessions and counters, with `maxmemory 1536mb --maxmemory-policy volatile-lru`. This note records why that policy, why Sidekiq's boot warning about it is expected, and what a rollback across the RDB format change costs. Read it before changing the policy, splitting the instance, or downgrading Redis.

## Why `volatile-lru`

`maxmemory-policy` applies to the whole instance, not per database, so Sidekiq's DB 0 inherits whatever the cache needs. `volatile-lru` evicts only keys that carry a TTL, which splits the instance along exactly the right line:

| Keyspace                               | DB  | TTL                                                          | Under `volatile-lru` |
| -------------------------------------- | --- | ------------------------------------------------------------ | -------------------- |
| Sidekiq `queue:*`, `retry`, `schedule` | 0   | none                                                         | never evicted        |
| Rails cache                            | 1   | store default `expires_in: 1.day`, call sites pass their own | evictable            |
| API usage counters                     | 1   | `expires_in: 8.days` per write                               | evictable            |
| Rack::Attack throttles                 | 1   | period-based                                                 | evictable            |
| Sessions                               | 2   | `expire_after: 2.hours`                                      | evictable            |

The policy only works while the cache has a real evictable keyspace: no cache write may use `expires_in: nil` or `0`. That held when checked; a TTL-less cache write would become unevictable and eat the headroom.

Rejected:

- **A second Redis accessory with `noeviction` for Sidekiq** (Sidekiq's own recommendation). Correct, but costs a new accessory, a second URL through `config/redis.yml` and the Kamal secrets, and a cutover of the queue data — a lot of moving parts for a failure mode that had never fired.
- **`noeviction` on the shared instance.** Safe for Sidekiq, but at the ceiling the cache starts returning write errors instead of shedding entries, so the cache would need its own bound or instance — the first option by another route.
- **`allkeys-lru`** (the previous setting). Drops Sidekiq's keys under pressure; see Measured.

## Sidekiq's boot warning is a false positive

Sidekiq warns on any policy other than `noeviction`:

```
WARNING: Your Redis instance will evict Sidekiq data under heavy load.
The 'noeviction' maxmemory policy is recommended (current policy: 'volatile-lru').
```

The check is a literal string comparison; it knows nothing about which keys are candidates. Silencing it would cost the rejected second instance. Sidekiq is not entirely TTL-free, so precisely:

| Sidekiq key                                   | TTL                      | If evicted                                                   |
| --------------------------------------------- | ------------------------ | ------------------------------------------------------------ |
| `queue:*`, `retry`, `schedule`, `dead`        | none                     | unreachable by the policy                                    |
| Heartbeat / process keys                      | 60s, rewritten every 10s | worker drops out of the Web UI until the next beat; cosmetic |
| `stat:processed:<date>`, `stat:failed:<date>` | 5 years                  | one day's counter                                            |
| Metrics histograms                            | 8 hours                  | a metric                                                     |
| `Sidekiq::Job::Iterable` state                | 30 days                  | an interrupted iterable job restarts from the beginning      |

Only the last row would do real damage, and the app does not use `Sidekiq::Job::Iterable`. `maintenance_tasks` uses Shopify's `job-iteration`, whose cursor is a Postgres column, not a Redis key. Sidekiq OSS never recovers jobs from the process set (a Pro feature), so an evicted heartbeat cannot lose or replay a job.

**If anyone adopts `Sidekiq::Job::Iterable`, this analysis no longer holds.**

## Measured

An isolated `redis:8.2.9-alpine` with `maxmemory 3mb`, two TTL-less Sidekiq keys (`queue:default`, `schedule`) planted first, then 24,000 cache writes at `SETEX ... 86400`:

| Policy         | Evicted keys | `queue:default` | `schedule` |
| -------------- | ------------ | --------------- | ---------- |
| `allkeys-lru`  | 21,853       | **gone**        | **gone**   |
| `volatile-lru` | 42,798       | intact          | intact     |

So the risk under `allkeys-lru` was real, and silent. A gentler first run (4,000 writes, 855 evictions) left both keys alive: LRU samples rather than sorts, so the failure needs sustained pressure to surface. That is why production reporting `evicted_keys:0` was never reassurance.

Under `volatile-lru`, a rising `evicted_keys` is the cache shedding as intended, not a regression.

The 8.x images load modules (`search`, `ReJSON`, `timeseries`, `bf`, `vectorset`) even with a custom `cmd`. Idle cost measured at ~21 MB RSS, so the 2 GB container and 1536 MB ceiling did not need to change.

## Rollback across 8.x needs `dump.rdb` deleted

- 7.2 writes RDB v11 (`REDIS0011`); 8.2 loads it, keeps the databases and their TTLs.
- 8.2 writes RDB v12 (`REDIS0012`); 7.2 refuses it with `Can't handle RDB format version 12` / `Fatal error loading the DB` and exits during startup.

Rolling the image back to 7.x therefore means deleting `dump.rdb` from the Redis data volume, which discards DB 0 — the Sidekiq queues. Drain the workers first so there is nothing in DB 0 to lose. The same applies to any future RDB format bump.

## Gem compatibility

No gem gated on the server version except Sidekiq, and only from below (it raises under 7.0.0). `redis` and `redis-client` do not inspect the version. Sidekiq, the Rails cache, `Redis::Store` sessions, Action Cable pubsub, Rack::Attack, `ApiUsageTracker`'s `scan_each` and a RESP3 handshake were all exercised against 8.2.9 with the production `cmd` before the cutover.
