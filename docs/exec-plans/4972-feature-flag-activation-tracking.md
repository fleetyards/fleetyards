# Feature flag activation history

## Goal

Every write to a Flipper flag leaves a row saying what changed, who changed it and what
state the flag ended up in — so "fully on since" is a query rather than a guess, and
`bin/feature-flags stale` can name the flags that are ready to be removed.

## Context

Resolves #4972.

The only activation signal today is `flipper_gates.created_at`, and it is wrong in three
directions: a boolean disable *deletes* the gate row rather than updating it, so switching
a flag off and on resets its age with no trace; `FeatureFlags::Synchronizer#apply!` calls
`flipper.remove(name)` on prune, taking every gate with it; and nothing records who acted
or through which surface.

That was established while writing #4960–#4969 — ten removal issues whose "fully on since"
dates were all read off `flipper_gates.created_at` and all really mean *"last switched on,
assuming nobody has touched it since"*.

## Decisions

### D1 — Listen to `feature_operation.flipper`, do not instrument the call sites

`flipper`'s Rails engine already defaults the instrumenter to `ActiveSupport::Notifications`:

```ruby
# flipper-1.4.2/lib/flipper/engine.rb
instrumenter: ENV.fetch('FLIPPER_INSTRUMENTER', 'ActiveSupport::Notifications').constantize,
```

So the events are published in production right now, with `Flipper::Instrumentation::LogSubscriber`
as the only listener. One subscriber therefore catches every write path without touching a
single call site:

| path | how it writes |
|---|---|
| `/admin/features` | the ten actions in `Admin::Api::V1::FeaturesController` |
| user self-service | `Api::V1::UserFeaturesController#enable` / `#disable` |
| fleet self-service | `Api::V1::FleetFeaturesController` |
| deploy | `FeatureFlags::Synchronizer#apply!` → `flipper.add` / `flipper.remove` |
| console, e2e scenarios | `Flipper.enable(...)` |

Rejected: writing the row from the admin controller. It is the obvious place and it misses
sync, self-service and the console — which is where the history nobody can reconstruct
actually lives.

### D2 — Store the resulting state, not just the operation

`state_after` holds `feature.state` (`on` / `off` / `conditional`) read straight after the
write. Storing only the operation means answering "was this fully on in July" by replaying
every row, and a replay cannot see writes from before the log existed. With `state_after`,
*fully on since* is the `created_at` of the earliest row in the current unbroken run of
`on`.

### D3 — `feature_name` is a string, not a foreign key

The row has to outlive the flag. `sync` prunes a flag and its gates together on the deploy
after it leaves `config/feature_flags.yml`, and the history of a flag we removed is the most
interesting history there is. Same reason the log is never pruned.

### D4 — Not paper_trail

`Flipper::Adapters::ActiveRecord::Gate` is an ActiveRecord model and `has_paper_trail` would
attach to it, but a boolean disable is a `destroy` rather than an `update`, gate rows have no
stable identity across a disable/re-enable cycle, and reconstructing feature state from gate-row
diffs is strictly harder than recording `feature.state` at write time. paper_trail would give
three rows of adapter noise per toggle.

### D5 — Attribution rides on `CurrentAttributes`, next to the existing whodunnit

The subscriber has no request context. `Admin::Api::BaseController` already solves this exact
problem for paper_trail with `before_action :set_paper_trail_whodunnit`; the flag source is set
in the same place. Unset means `console`, which is the honest answer for a `bin/rails runner`.

## What changed

### Phase 1 — the log

1. Migration `create_feature_flag_changes`, `id: :uuid`, no `updated_at` (rows are never
   edited), index on `(feature_name, created_at DESC)`.

   | column | type | note |
   |---|---|---|
   | `feature_name` | string, not null | plain string by D3 |
   | `operation` | string, not null | `enable` / `disable` / `add` / `remove` / `clear` |
   | `gate_name` | string | `boolean` / `actor` / `group` / `percentage_of_actors` / `percentage_of_time` |
   | `thing` | string | `User;<uuid>`, a group name, `25` |
   | `state_after` | string, not null | D2 |
   | `admin_user_id` | uuid, fk, nullable | |
   | `user_id` | uuid, fk, nullable | self-service |
   | `source` | string, not null | `admin` / `self_service` / `sync` / `console` / `backfill` |

2. `FeatureFlagChange` model with `record!(payload)` and `self.fully_on_since(name)`.
3. `FeatureFlags::Current < ActiveSupport::CurrentAttributes` — `source`, `admin_user`, `user`,
   with a `with(source:, …)` block helper that restores the previous values so a nested write
   cannot strand the outer one.
4. `FeatureFlags::AuditSubscriber`, filtering to the five mutating operations, registered from
   `config/initializers/feature_flag_audit.rb` the way the fleet-event subscribers already are.
5. `test/support/flipper_audit_test_helpers.rb` — see the discovery log.

### Phase 2 — attribution

1. `Admin::Api::BaseController` sets `source: :admin` and the acting admin, beside
   `set_paper_trail_whodunnit`.
2. `FeatureGrantsConcern` sets `source: :self_service` and the acting user — **not**
   `Api::BaseController` as first planned. The concern is included by exactly the two
   self-service controllers, and labelling every flag write that passes through the public
   API as self-service would be a lie the first time one comes from somewhere else.
3. Both actors are stored as procs and resolved at write time — see the discovery log.
4. `FeatureFlags::Synchronizer#apply!` wraps its adds and removes in `Current.with(source:
   :sync)`. A block rather than an assignment, because `sync` also runs from a console and
   must not leave its source behind.

### Phase 3 — backfill

Data migration seeding one `add` row per `flipper_features` row and one `enable` row per
surviving `flipper_gates` row, `source: "backfill"`, no actor. `state_after` is replayed
cumulatively over the gates that existed at each step, so the final row always matches the
flag's real state today.

It is a lower bound, not the truth, and the migration comment says why it cannot be more:
a boolean disable deletes the row, and a boolean *enable* runs `set(clear: true)` which
deletes every actor and group row first — so the rollout that preceded a fully-open flag is
already gone and no backfill can recover it.

Timestamps come from `updated_at` rather than `created_at`: a percentage gate is updated in
place, so its `created_at` is when a percentage was first set rather than when it took the
value the row now holds. Every other gate is written once and the two are identical.

### Phase 4 — reading it back

1. `_feature.jbuilder` gains `fullyOnSince`, `lastChangedAt`, `lastChangedBy`.
2. `Admin::V1::Schemas::Feature` gains the same three. It is `additionalProperties: false`
   and hand-written, so the jbuilder change does nothing until this is edited too.
3. `/admin/features` shows "on for everyone since …" per row, and a per-flag history panel
   on the detail view — the rollout path (actors → percentage → boolean) is the part that is
   unknowable today.
4. `bin/feature-flags stale` — every non-`permanent` flag whose `fully_on_since` is older
   than N days. This is the payoff: the command that would have produced #4960–#4969 without
   anyone reading a gate table by hand.

## Intent Verification

- [x] **Every write path logs.** An admin toggle, a self-service opt-in, a console
      `Flipper.enable` and a `Synchronizer` prune each leave exactly one row, with the right
      `source`.
- [x] **`enabled?` logs nothing.** `feature_operation.flipper` fires on every
      `Flipper.enabled?` call on every request; the filter has to be the first line and the
      log must stay empty under read traffic.
- [x] **A failing log never breaks a toggle.** `record!` raising leaves `@feature.enable`
      successful and reports to AppSignal. An audit log that can 500 the admin page is worse
      than no audit log.
- [x] **`fully_on_since` survives an off/on cycle** — the case `flipper_gates` gets wrong
      today.
- [x] **A pruned flag keeps its history.** `Synchronizer` removing a flag leaves its rows in
      place.
- [ ] **The admin page shows the date** and the API schema check passes.

## Key files

| File | Role |
|------|------|
| `db/migrate/*_create_feature_flag_changes.rb` | the table |
| `app/models/feature_flag_change.rb` | `record!`, `fully_on_since` |
| `lib/feature_flags/current.rb` | `CurrentAttributes` for source + actor |
| `config/initializers/feature_flag_audit.rb` | the `feature_operation.flipper` subscriber |
| `app/controllers/admin/api/base_controller.rb` | sets `source: :admin`, beside `set_paper_trail_whodunnit` |
| `app/controllers/api/base_controller.rb` | sets `source: :self_service` |
| `lib/feature_flags/synchronizer.rb` | tags its writes `source: :sync`; must not prune the log |
| `app/views/admin/api/v1/features/_feature.jbuilder` | `fullyOnSince`, `lastChangedAt`, `lastChangedBy` |
| `app/api_components/admin/v1/schemas/feature.rb` | hand-written, `additionalProperties: false` |
| `app/frontend/admin/pages/maintenance/features.vue` | the column and the history panel |
| `bin/feature-flags` | the `stale` command |

## Not in scope (deferred)

- **Retention or pruning** — 23 flags with a handful of changes each. The rows are most
  valuable when they are old.
- **Acting on staleness automatically** — `bin/feature-flags stale` prints; opening the issue
  stays a human step.
- **The ten removals themselves** — #4960–#4969, independent of this.

## Discovery Log

- **2026-09-16** Plan created. Confirmed against `flipper-1.4.2` that the instrumenter
  already defaults to `ActiveSupport::Notifications`, that the event is
  `feature_operation.flipper` with payload `{feature_name, operation, gate_name, thing, result}`,
  and that `enabled?` and `exist?` publish on the same event name — which is what makes the
  operation filter load-bearing rather than tidy.
- **2026-09-16** Phase 1 built, 15 tests green, `bin/ruby-lint` clean.
  - `flipper/test_help` builds the test instance as `Flipper.new(config.adapter)` with **no
    instrumenter argument**, so it gets `Instrumenters::Noop` and `feature_operation.flipper`
    never fires in the test environment. The subscriber would have looked dead no matter what
    it did. `with_flag_auditing` installs an instrumented instance for the duration of a test;
    it is opt-in rather than global because a great many tests enable a flag in setup and would
    otherwise write rows nothing asserts on. Worth knowing before Phase 2's controller tests.
  - Reading `feature.state` back inside the subscriber is safe: `Flipper::Adapters::Memoizable`
    expires its cache entry in `enable`, `disable`, `clear` and `remove`, and the notification
    is published after the adapter call returns — so it is never the pre-write value. Checked
    in the gem rather than assumed, because a stale read here would silently record the wrong
    state forever.
- **2026-09-16** Phase 2 built, 78 feature-controller tests and all 957 admin integration
  tests green.
  - **Eager attribution broke OAuth scope enforcement.** Setting
    `FeatureFlags::Current.user = current_resource_owner` in a before_action turned three
    `401`s into `200`s. `Api::BaseController#current_resource_owner` memoises into
    `@current_user` — the same ivar Devise's `current_user` reads — so calling it before the
    `doorkeeper_authorize!` callbacks makes `user_signed_in?` true, and the
    `unless: :user_signed_in?` guard on those callbacks skips the scope check entirely. A
    wrong-scope token then gets a 200. Both actors are now stored as procs and resolved in
    `FeatureFlagChange.record!`, which is what `set_paper_trail_whodunnit` has always done in
    these controllers — the proc there is load-bearing, not a style choice.
- **2026-09-16** Phase 3 built, 66 related tests green, and smoke-tested against the real
  24-flag registry in the worktree database.
  - **`gate_name` meant two different things.** Flipper names the actor and group gates in
    the singular (`actor`, `group`) but stores them plural (`actors`, `groups`), and the
    notification carries the *name* while `flipper_gates` carries the *key* — so a backfilled
    row and a live one would have disagreed about what the same gate is called, silently, for
    the two gate types that matter most. `FeatureFlagChange::GATE_NAMES_BY_STORAGE_KEY` is
    derived from Flipper's own gate objects rather than listed, so a gate added by a future
    flipper cannot drift.
  - **A percentage of 0 is the gate's default**, so the presence of the row is not enough to
    call a flag conditional — `Flipper::Feature#state` would report it off.
  - `bin/rails data:migrate` cannot complete on a *fresh* database, and has not been able to
    since long before this branch: `db/data/20260309112027_create_feature_flags.rb` writes
    `FeatureSetting#self_service=`, a column replaced by `self_service_user` /
    `self_service_fleet`. Production is unaffected, since it ran that migration when the
    column existed. Not touched here — it is its own fix.

## Progress

- [x] Phase 1 — the log
- [x] Phase 2 — attribution
- [x] Phase 3 — backfill
- [ ] Phase 4 — reading it back
