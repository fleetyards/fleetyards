# Upgrade Redis 7.2 → 8.2 and stop the eviction policy from reaching Sidekiq

## Goal

Every environment runs a Redis from the 8.2 line, and the production instance can no longer evict a Sidekiq job under memory pressure.

## Context

`config/deploy.yml` pins the production accessory to `redis:7.2.15` and starts it with `redis-server --maxmemory 1536mb --maxmemory-policy allkeys-lru`. CI (×4 workflows) and `docker-compose.yml` pin `redis:7.2.15-alpine`.

Two defects sit on that one `cmd:` line, which is why they are resolved together — one accessory restart instead of two, and the deploy already needs a drained-queue window, which is the safest moment to change an eviction policy.

Neither is urgent. 7.2 is supported until 2029-12-01, and production reports `evicted_keys:0` / `total_eviction_exceeded_time:0`, so nothing is actively being dropped.

Resolves #4334, resolves #4335

## Decisions

### D1 — Target 8.2.9, not the 8.2.8 named in the issue

The 8.2 line is supported until 2030-09-01; 8.0 is nearly EOL and 8.4–8.10 have no committed support window. Within the line, take the newest patch: `8.2.9` was published 2026-08-20, a month after the `8.2.8` the issue researched, and is the same 27.8 MB compressed.

### D2 — `volatile-lru`, not a second Redis accessory

`maxmemory-policy` applies to the whole instance, not per database, so Sidekiq's DB 0 inherits whatever the cache needs. `volatile-lru` evicts **only keys that carry a TTL**, which splits the instance along exactly the line that matters here:

| Keyspace | DB | TTL | Under `volatile-lru` |
| --- | --- | --- | --- |
| Sidekiq `queue:*`, `retry`, `schedule` | 0 | none | never evicted |
| Rails cache | 1 | `expires_in: 1.day` store default, every call site passes its own | evictable |
| API usage counters | 1 | `expires_in: 8.days` per write | evictable |
| Rack::Attack throttles | 1 | period-based, set by Rack::Attack | evictable |
| Sessions | 2 | `expire_after: 2.hours` | evictable |

Verified: no call site writes to the cache with `expires_in: nil` or `0`, so the safety valve keeps a real keyspace to work on.

- Rejected: **a second accessory with `noeviction`** (Sidekiq's own recommendation). Correct, but it costs a new accessory, a second URL threaded through `config/redis.yml` and the Kamal secrets, and a cutover for the queue data already in DB 0 — a large amount of moving parts for a failure mode that has never fired.
- Rejected: **`noeviction` on the shared instance.** Safe for Sidekiq, but at the ceiling the cache starts returning write errors instead of quietly shedding old entries, so the cache would need its own bound or its own instance — which is the rejected option above by another route.
- Rejected: **leaving the policy alone.** The line is being edited anyway.

### D3 — Accept Sidekiq's boot warning

`sidekiq/cli.rb:80-91` warns on any policy other than `noeviction`:

```
WARNING: Your Redis instance will evict Sidekiq data under heavy load.
The 'noeviction' maxmemory policy is recommended (current policy: 'volatile-lru').
```

The check is a string comparison against `noeviction`; it does not know that Sidekiq's own keys carry no TTL and are therefore unreachable by `volatile-lru`. The warning is a false positive here, and the `cmd:` line carries a comment saying so. Silencing it is what D2's rejected option costs.

### D4 — Rollback means deleting `dump.rdb`

8.x writes RDB v12. 8.2.9 reads a 7.2.15 dump, but 7.2.15 refuses a v12 dump outright (`Can't handle RDB format version 12`) and exits during startup. Rolling the image back therefore requires deleting `dump.rdb` from the `data:/data` volume, which discards DB 0. Draining the queues before the cutover (Phase 3) is what makes that acceptable rather than destructive.

## What changed

### Phase 1 — CI and local on 8.2.9

1. `.github/workflows/ruby-tests.job.yml`, `seeds.job.yml`, `api-schema-check.job.yml`, `e2e.job.yml`: service image `redis:7.2.15-alpine` → `redis:8.2.9-alpine`.
2. `docker-compose.yml`: `redis:7.2.15-alpine` → `redis:8.2.9-alpine`. The `--databases 1024` command stays; it is what gives each worktree its own band.
3. Push and let CI run the full Ruby suite, seeds, schema check and e2e against 8.2.9. This is the evidence for Phase 2 — production is not touched until it is green.

### Phase 2 — Production accessory

1. `config/deploy.yml`: `image: redis:7.2.15` → `redis:8.2.9`.
2. Same file: `--maxmemory-policy allkeys-lru` → `--maxmemory-policy volatile-lru`, with a comment recording why (D2/D3).

### Phase 3 — Cutover

Nothing here is in the diff; it is the deploy procedure, and it needs a human at the terminal.

1. **Before**: record the starting state — `bin/accessory-live exec redis -- redis-cli INFO memory | grep -E 'used_memory_human|maxmemory_human'`, `INFO keyspace`, and `INFO stats | grep evicted_keys`. If `used_memory` is anywhere near the 1536 MB ceiling, stop and reconsider the ceiling first.
2. **Drain**: quiet the worker role and let in-flight jobs finish, so DB 0 is as close to empty as it gets. This bounds the rollback loss to nothing.
3. **Deploy**: `bin/deploy` for the config, then `bin/accessory-live reboot redis` to recreate the container on the new image and `cmd`.
4. **Verify**: `INFO server` reports `redis_version:8.2.9`; `CONFIG GET maxmemory-policy` returns `volatile-lru`; `INFO keyspace` still shows the databases from step 1.
5. **Resume**: bring the worker role back and confirm jobs are being processed.
6. **Rollback if needed**: revert the image pin, delete `dump.rdb` on the `data:/data` volume, redeploy — accepting the loss of whatever is in DB 0 (which step 2 made empty).

Watch for: the 8.x images load modules (`search`, `ReJSON`, `timeseries`, `bf`, `vectorset`) even with a custom `cmd`. Measured at ~21 MB RSS idle in a 2 GB container, so `memory: 2g` and `maxmemory 1536mb` stay as they are.

## Measured

Against real containers, not from the docs. An isolated `redis:8.2.9-alpine` on port 63799, `maxmemory 3mb`, two TTL-less Sidekiq keys (`queue:default`, `schedule`) planted first, then 24,000 cache writes at `SETEX ... 86400` to force sustained eviction.

| Policy | Evicted keys | `queue:default` | `schedule` |
| --- | --- | --- | --- |
| `allkeys-lru` (today's production) | 21,853 | **gone** | **gone** |
| `volatile-lru` (this change) | 42,798 | intact | intact |

So #4335 is not theoretical: under sustained pressure the current policy does drop Sidekiq's keyspace, and it drops it silently. A first, gentler run (4,000 writes, 855 evictions) left both keys alive — LRU samples rather than sorts, so the failure needs pressure to surface, which is exactly why `evicted_keys:0` in production is not reassurance.

RDB compatibility, both directions:

- 7.2.15 writes `REDIS0011`; 8.2.9 starts on that dump, keeps `db0`/`db1` and their TTLs, and applies `volatile-lru`.
- 8.2.9 writes `REDIS0012`; 7.2.15 refuses it with `# Can't handle RDB format version 12` / `# Fatal error loading the DB` and exits. D4's rollback step is required, not precautionary.
- `MODULE LIST` on 8.2.9 with a custom `cmd`: `timeseries`, `search`, `bf`, `vectorset`, `ReJSON` — loaded, as the issue found.

## Compatibility, verified against the installed gems

`rails 8.1.3.1` / `actioncable 8.1.3.1`, `redis 5.4.1`, `redis-client 0.30.1`, `sidekiq 8.1.7`, `sidekiq-scheduler 6.0.2`, `redis-store 1.12.0`, `redis-actionpack 5.5.0`.

No gem gates on the server version except Sidekiq, and only from below: `sidekiq/cli.rb:78` raises for anything under 7.0.0 and has no upper bound. `redis` and `redis-client` do not inspect the version at all.

Rather than infer support from that, every Redis consumer in the app was exercised against a real `redis:8.2.9-alpine` started with the production `cmd` — 13 checks, all passing:

- **Sidekiq** — enqueue / read back / delete on `queue:*`, `perform_in` onto the scheduled set, a retry-set round-trip, `Sidekiq::Stats` and the process set
- **Sidekiq's keys carry no TTL** — asserted directly, since that is the premise `volatile-lru` rests on
- **Rails cache** — `write`/`read`/`fetch`/`increment`/`delete_matched`, plus an assertion that a written key really does get a TTL
- **Sessions** — `Redis::Store` round-trip with `expire_after`, TTL confirmed
- **Action Cable** — redis pubsub across two connections with a `channel_prefix`
- **Rack::Attack** — throttle counter through its Redis-backed store
- **`ApiUsageTracker`** — `scan_each` over the namespaced keyspace
- **RESP3** — explicit `HELLO 3` handshake and round-trip

And a real `sidekiq` server booted against it, picked up a job and shut down cleanly. Its boot output is exactly D3's prediction, reproduced verbatim:

```
WARNING: Your Redis instance will evict Sidekiq data under heavy load.
The 'noeviction' maxmemory policy is recommended (current policy: 'volatile-lru').
```

Followed, in the same run, by `class=ProbeJob: start` / `elapsed=0.0: done`.

## Intent Verification

- [ ] **CI runs against 8.2.9** — all four workflows show the new image and pass, including the full Ruby suite
- [ ] **Production reports 8.2.9** — `INFO server` after the accessory reboot
- [ ] **Sidekiq's keyspace is unevictable** — `CONFIG GET maxmemory-policy` returns `volatile-lru`, and Sidekiq's keys carry no TTL
- [ ] **Nothing was lost in the cutover** — `INFO keyspace` shows the same databases before and after, and the worker processes jobs again
- [ ] **The cache still sheds** — `evicted_keys` may now rise from 0 under pressure; that is the valve working, not a regression
