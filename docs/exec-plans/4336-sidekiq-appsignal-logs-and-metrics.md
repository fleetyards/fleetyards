# Sidekiq is invisible in AppSignal — no logs and no metrics from the worker role

## Goal

Sidekiq's worker role reports both its log output and its queue/Redis metrics to AppSignal, so background-job problems are diagnosable there instead of being invisible.

## Context

The `worker` role reports nothing to AppSignal. Every ingested log line belongs to `group=rails`; a `group!=rails` query returns zero results. The `sidekiq_*` metrics are registered names but return no data points, so the built-in Sidekiq dashboard renders empty while appearing functional.

This surfaced while trying to confirm whether Sidekiq warns about the Redis `allkeys-lru` eviction policy. That question could not be answered from AppSignal at all, which is what motivated this issue.

Resolves #4336

## Decisions

### D1 — Broadcast `Sidekiq.logger`, do not reroute it to `Rails.logger`

Sidekiq keeps its own logger; it never writes through `Rails.logger`, which is the only logger `production.rb` broadcasts to AppSignal.

- **Chosen:** `Appsignal::Logger#broadcast_to`. Build an `Appsignal::Logger.new("sidekiq")`, broadcast it to Sidekiq's existing logger, and assign it as `config.logger`.
- Rejected: `ActiveSupport::BroadcastLogger`. This was the original choice and it was wrong. The AppSignal gem implements its own broadcasting *specifically* to avoid the Rails one (`appsignal/logger.rb:233-288`): Rails' version runs the block passed to `.tagged` once per broadcast logger, duplicating log lines, and in one linked Rails issue turns the Rack response into an array of responses, breaking the app outright.
- Rejected: `config.logger = Rails.logger`. Discards Sidekiq's formatting, changes container stdout in a way that affects `kamal app logs`, and couples worker logging to Rails' tagged-logging config.

### D2 — Give Sidekiq its own AppSignal logger group

Use `Appsignal::Logger.new("sidekiq")` rather than reusing `"rails"`. The group is what makes `group=sidekiq` filtering possible in the AppSignal UI, and mixing worker output into the `rails` group would make the two indistinguishable — the exact problem being fixed.

### D3 — Guard on `Appsignal.active?`, not on `Rails.env`

`production.rb` sets up its broadcast inline, and `staging.rb` has no equivalent, so staging currently ships no Rails logs to AppSignal either. Guarding the Sidekiq broadcast on `Appsignal.active?` means it works in every environment where AppSignal is enabled without duplicating environment-specific wiring — and makes staging usable for verifying this change.

### D4 — Diagnose the metrics gap before changing anything

The log cause is confirmed in code. The metrics cause is not. `Appsignal::Hooks::SidekiqHook#install` (`appsignal/hooks/sidekiq.rb:29`) registers the probe only when `defined?(::Sidekiq)` and `config[:instrument_sidekiq]` are both true at `Appsignal.start` time, and `Appsignal::Probes.start` runs only when `enable_minutely_probes` is set (`appsignal.rb:151`). Any of those can silently no-op. Guessing a fix risks shipping a change that alters nothing, so Phase 2 starts with reading the agent's own log inside the worker container.

## What changed

### Phase 1 — Sidekiq logs reach AppSignal

1. In `config/initializers/sidekiq.rb`, inside `Sidekiq.configure_server`, wrap `config.logger` in a broadcast that adds `Appsignal::Logger.new("sidekiq")`.
2. Guard on `Appsignal.active?` so local/test runs are unaffected.
3. Confirm STDOUT output is unchanged, so `kamal app logs -r worker` still behaves as before.

### Phase 2 — Sidekiq metrics reach AppSignal

1. Read the AppSignal agent log inside the worker container (`working_directory_path` is `/tmp/appsignal`, per `config/appsignal.yml`) — probe registration failures and probe exceptions are logged there.
2. Confirm the hook installed at all: check that `instrument_sidekiq` and `enable_minutely_probes` are both on in the running config.
3. Confirm the `background` namespace has *recent* transactions, which distinguishes "agent not running in the worker" from "probe specifically not running".
4. Apply whatever the diagnosis indicates; record the actual cause in this plan's Discovery Log.

### Phase 3 — Verify

1. Deploy to staging, generate job activity, confirm both log lines and metrics appear.
2. Deploy to production, confirm the Sidekiq dashboard is no longer empty.

## Intent Verification

- [ ] **Sidekiq log lines are queryable in AppSignal** — a `group=sidekiq` query returns worker output, and `group!=rails` is no longer empty
- [ ] **Container stdout is unchanged** — `kamal app logs -r worker` shows the same format as before
- [ ] **Sidekiq metrics report data** — `sidekiq_queue_length` and `sidekiq_queue_latency` return data points for a recent window
- [ ] **The Sidekiq dashboard renders non-empty** in the AppSignal UI
- [ ] **A Sidekiq-level warning is now visible** — specifically, whatever Sidekiq says at boot about the Redis eviction policy, which is the verification gap that blocked #4335

## Key files

| File | Role |
|------|------|
| `config/initializers/sidekiq.rb` | Sidekiq server/client config; where the logger broadcast is added |
| `config/environments/production.rb` | Existing `Rails.logger` → AppSignal broadcast (lines 75–85); the pattern being mirrored |
| `config/environments/staging.rb` | Has no logger broadcast; relevant to D3 |
| `config/appsignal.yml` | `working_directory_path: /tmp/appsignal` — where the agent log lives |
| `config/deploy.yml` | `worker` role definition (`bundle exec sidekiq -C config/sidekiq.yml`) |

## Not in scope (deferred)

- **Redis eviction policy (#4335)** — separate defect; this change only makes its symptoms observable
- **Redis 8.2 upgrade (#4334)** — unrelated to observability
- **Adding the Rails logger broadcast to `staging.rb`** — a real gap found along the way, but a different fix; worth its own change if staging log visibility is wanted
- **Alerting on queue depth** — once metrics report, triggers become possible, but configuring them is follow-up work

## Discovery Log

- **2026-08-12** Confirmed the log root cause: `production.rb:75-85` broadcasts only `Rails.logger`; Sidekiq's own logger is never attached. Verified empirically that AppSignal receives only `group=rails` lines despite three worker boots that day.
- **2026-08-12** Traced probe registration to `appsignal/hooks/sidekiq.rb:29` (gem 4.9.1) and minutely-probe startup to `appsignal.rb:151`. Metrics cause not yet determined — deliberately left to Phase 2 diagnosis.
- **2026-08-12** Noted AppSignal's log query window on this account is 24 hours, and out-of-range queries return empty rather than erroring.
- **2026-08-12** D1 reversed during implementation. `ActiveSupport::BroadcastLogger` is actively unsafe here — the AppSignal gem documents that Rails' broadcasting duplicates tagged log lines and can break the Rack response entirely, which is why it ships its own `broadcast_to`. Used the gem's implementation instead.
- **2026-08-12** Confirmed the `Appsignal.active?` guard is sound. The railtie defaults to `start_at = :on_load`, whose initializer runs before `config/initializers/*`, so AppSignal has already started when the Sidekiq initializer is evaluated. Had this been false, the guard would have been permanently false in production and the fix would have silently done nothing.
- **2026-08-12** Phase 1 verified locally by booting Sidekiq both ways: with AppSignal active `config.logger` is an `Appsignal::Logger` broadcasting to `[Sidekiq::Logger]`; with it inactive the logger is left as `Sidekiq::Logger`. Sidekiq's stdout format was unchanged in both runs.

## Progress

- [x] Phase 1 — Sidekiq logs (`711c09c82`, verified locally; awaiting deploy to confirm ingestion)
- [ ] Phase 2 — Sidekiq metrics
- [ ] Phase 3 — Verify
