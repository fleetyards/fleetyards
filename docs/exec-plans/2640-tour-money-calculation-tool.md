# Tour money calculation tool

## Goal

A tour — either a fleet event or a standalone one created from `/tools/` — carries a payout
ledger where participants record what they spent and what they took in, and the site computes
who has to send what to whom.

## Context

Issue #2640 asks for a tool where an event is created with a set of users, each user records
money spent or received for the event, and at the end the site produces a payout list.

The issue was opened in August 2023 and predates the entire `FleetEvent` system, which now
carries participants (`fleet_event_signups`), a lifecycle ending in `completed`, per-event
admins and fleet-role privileges. The money side does not need to rebuild any of that. It does
need to work for an ad-hoc group who are not in one fleet, which is what the issue literally
describes — hence a ledger with a polymorphic owner.

Resolves #2640

## Decisions

### D1 — One ledger, two owners

`PayoutLedger` belongs to a polymorphic `subject`, either a `FleetEvent` or a new standalone
`Tour`, one ledger per subject. Both owners ship together.

Rejected: attaching the ledger only to `FleetEvent`. It is much cheaper — signups, privileges
and the lifecycle all come free — but it forces every tour through a fleet, which is not what
the issue describes. Rejected: two parallel table sets the way `inventories` /
`fleet_inventories` are split. That split exists because the two sides carry genuinely
different columns; here the ledger is identical and only the authorization differs.

The cost is that `PayoutLedgerPolicy` has to branch on `subject_type`. That branch is the one
place the two owners are allowed to diverge.

### D2 — Expenses and income, not cost-splitting

Entries are typed `expense` or `income`. Costs are reimbursed to whoever paid them first, and
the remaining profit is divided across participants.

Rejected: plain Splitwise-style cost-splitting. A Star Citizen tour usually earns money — a
cargo run, a mining trip — and a tool that can only divide costs cannot express the payout the
issue asks for.

### D3 — No currency column

Amounts are a bare `decimal(15, 2)`, matching `item_prices.price` and `models.price`. There is
no currency column and no currency string in Ruby.

Display goes through the existing `toUEC` helper in
`app/frontend/shared/utils/I18nHelpers.ts`, which reads `number.units.uec`. "aUEC" is the
alpha-only name for the in-game currency, and that translation value is the only place it
lives — so renaming it later is one edit per locale, not a migration.

Rejected: `amount_cents` integers. That convention exists on `supporter_contributions` and
`funding_goals` specifically because payment processors report cents; `decimal(15, 2)` is
already exact for our arithmetic.

### D4 — An explicit participant list, guests allowed

The ledger owns participant rows. Opening a ledger on a fleet event seeds them from the
event's non-withdrawn signups; an organiser can then add or remove people. A participant may
carry a free-text `name` with no `user_id`, for someone on the tour with no FleetYards
account — the precedent is `SupporterContribution`, the one existing model that can name a
contributor who has no account.

Rejected: deriving participants live from signups. A withdrawn signup would silently rewrite
everyone's share after the fact, and a friend who came along without signing up could not be
included at all.

### D5 — Derived while open, frozen on settle

Balances and transfers are computed per request while the ledger is `open` and never stored —
the rationale `StockPosition` gives for not storing derived totals applies unchanged. `settle!`
is the deliberate exception: it materialises the computed transfers into `payout_transfers`
rows and freezes the ledger, because once people start paying against the list it has to stop
moving. `reopen!` deletes them again.

### D6 — The standalone tour is a tool, under `/tools/`

`/tools/tours/` rather than a new top-level section. The issue asks for a *tool*, and
`tools_travel_times` / `tools_cargo_grids` already establish the section and its per-tool flag
convention.

### D7 — One feature flag for both surfaces

`tour_payouts` in `config/feature_flags.yml`. `FeatureSetting` carries `self_service_user` and
`self_service_fleet` independently for a single flag name, which is exactly this case: a fleet
toggle for the event ledger and a user toggle for the standalone tool, from one flag.

## What changed

### Phase 1 — Schema

Five migrations. All tables `id: :uuid, default: -> { "gen_random_uuid()" }`; every model gets
an `annotate` schema header.

1. `tours` — `title`, `description`, `slug`, `starts_at`, `status` (`open`/`settled`/
   `cancelled`), `settled_at`, `cancelled_at`, `invite_token`, `created_by_id`. Unique on
   `slug` and on `invite_token`.
2. `payout_ledgers` — `subject_type`/`subject_id`, `status` (`open`/`settled`), `settled_at`,
   `settled_by_id`, `notes`. Unique index on `[subject_type, subject_id]`, so a subject has at
   most one ledger.
3. `payout_participants` — `payout_ledger_id`, nullable `user_id`, `name`, `added_by_id`.
   Unique on `[payout_ledger_id, user_id] WHERE user_id IS NOT NULL`.
4. `payout_entries` — `payout_ledger_id`, `payout_participant_id`, `entry_type`
   (`expense: 0`, `income: 1`), `amount decimal(15,2)`, `description`, `notes`, `occurred_at`,
   `recorded_by_id`.
5. `payout_transfers` — `payout_ledger_id`, `from_participant_id`, `to_participant_id`,
   `amount decimal(15,2)`, `confirmed_at`, `confirmed_by_id`.

Amounts are always positive; direction is carried by `entry_type`, the way
`InventoryLedgerEntry` carries deposit/withdrawal.

### Phase 2 — Models

1. `Tour` — AASM (`column: :status`, `timestamps: true`), `open → settled`, plus `cancel`.
   Slug generated via `SlugConcern#generate_slug` and prefixed with the first id segment, the
   way `FleetEvent#update_slug` does it. `invite_token` from `SecureRandom.hex(4)`, the
   `FleetInviteUrl` convention. `has_one :payout_ledger, as: :subject`.
2. `PayoutLedger` — polymorphic `subject` with `touch: true`, an inclusion validation on
   `SUBJECT_TYPES = %w[FleetEvent Tour]` (an unconstrained polymorphic `belongs_to` would
   accept any model in the app — the reasoning behind `InventoryLedgerEntry::ITEM_TYPES`),
   `#settle!` / `#reopen!`, and `#seed_participants_from_subject!`.
3. `PayoutParticipant` — `name` required when `user_id` is nil, `#display_name`, and a
   `before_destroy` that refuses while the participant has entries.
4. `PayoutEntry` — `enum :entry_type`, `amount` greater than zero, participant must belong to
   the same ledger, and no writes once the ledger is settled.
5. `PayoutTransfer` — both sides `class_name: "PayoutParticipant"`, `#confirm!` /
   `#unconfirm!`.

### Phase 3 — The settlement service

`app/lib/payouts/settlement.rb` (services live in `app/lib/`, namespaced — cf.
`app/lib/calendars/`, `app/lib/notifications/`).

For `n` participants:

```
paid_i  = Σ expense amounts recorded against participant i
held_i  = Σ income  amounts recorded against participant i
profit  = Σ held − Σ paid
share_i = profit / n
net_i   = (held_i − paid_i) − share_i      # > 0 → i owes, < 0 → i is owed
```

`Σ net_i == 0` by construction. Transfers come from a greedy min-cash-flow pass: repeatedly
match the largest debtor against the largest creditor, yielding at most `n − 1` transfers.

Two things the implementation has to get right:

- **Integer minor units throughout.** Multiply by 100 on the way in, divide on the way out. No
  `Float` anywhere in the path.
- **Deterministic rounding.** `profit / n` rarely divides evenly. Distribute the remainder by
  the largest-remainder method in a stable participant order, so `Σ share_i == profit` exactly
  and the same ledger always settles the same way.

### Phase 4 — Permissions and the flag

1. `config/feature_flags.yml` gains `tour_payouts`. Then `bin/feature-flags validate` and
   `bin/feature-flags sync`. The self-service toggles are set at `/admin/features`, never in
   code. The flag has to be in the YAML **before** `bin/generate-schema`, or
   `FeatureFlagName.TOUR_PAYOUTS` will not exist in TypeScript.
2. `PayoutLedger::AVAILABLE_PRIVILEGES` = `fleet:payouts:{read,create,update,delete,manage}`,
   with `DEFAULT_PRIVILEGES` granting `manage` to officers and `read` + `create` to members.
   Registered as `"payouts"` in `FleetRole::PRIVILEGE_GROUPS`.
3. A `db/data/` migration backfilling existing roles, modelled on
   `db/data/20260504100000_grant_mission_privileges_to_existing_roles.rb`.
   `setup_default_roles!` only runs when a fleet is created, so without this every existing
   fleet gets a 403 on a feature that looks switched on.
4. Policies: `PayoutLedgerPolicy < FleetBasePolicy` branching on `subject_type` — fleet
   membership privileges plus `FleetEvent#event_moderator_or_admin?` for an event, participant
   or creator for a tour. `PayoutEntryPolicy` / `PayoutParticipantPolicy` /
   `PayoutTransferPolicy` delegate through `context: {payout_ledger:}`, the pattern
   `FleetEventSignupPolicy` uses with `context: {fleet_event:}`. Strong params come from
   `params_filter`.

### Phase 5 — API

Routes in new `config/routes/api/payouts_routes.rb` and `config/routes/api/tours_routes.rb`,
both `draw`n from `config/routes/api/v1_routes.rb`.

The ledger's children are addressed top-level by ledger id rather than nested under both
owners — the precedent is `fleet_event_slots`, which lives at `/fleet-event-slots/:id` despite
sitting deep in the event tree. Only creation and lookup are owner-scoped:

```
GET/POST  /fleets/:fleet_slug/events/:slug/payouts
GET/POST  /tours/:slug/payouts

resources :payout_ledgers, path: "payouts", only: %i[show] do
  member { put :settle; put :reopen; get :balances }
  resources :payout_participants, path: "participants", only: %i[index create destroy]
  resources :payout_entries,      path: "entries",      only: %i[index create update destroy]
  resources :payout_transfers,    path: "transfers",    only: %i[index]
end

resources :tours, param: :slug, only: %i[index show create update destroy]
```

Controllers follow `missions_controller.rb`: `authorize!` on every action,
`doorkeeper_authorize!` scope pairs, `result_with_pagination` + `pagination_header` on index
actions, `ValidationError.new("payout_entries.create", errors: …)` for 400s.

Jbuilder in `app/views/api/v1/payout_*/` and `tours/`, four files each — `_base` (uncached
attributes), `_<singular>` (`json.cache! ["v1", record]`), `index` (`json.items` +
`api/shared/meta`), `show`. Balances and transfers are computed per request, so they render
outside any cache block.

OpenAPI components under `app/api_components/v1/schemas/payouts/`, with the enums in
`v1/schemas/enums/` and **not** `shared/v1/` — a shared enum leaks into the admin schema.

### Phase 6 — Frontend

1. Event ledger: a `:event/payouts/` route in
   `app/frontend/frontend/pages/fleets/[slug]/events/routes.ts` with
   `feature: FeatureFlagName.TOUR_PAYOUTS`, `featureScope: "fleet"` and
   `access: ["fleet:payouts:read", "fleet:payouts:manage", "fleet:manage"]`, a link from the
   event page, and the route name added to `app/frontend/frontend/types/routes.ts`.
2. Standalone tours: `app/frontend/frontend/pages/tools/tours/routes.ts` mounted from
   `pages/tools/routes.ts`, giving `/tools/tours/`, `/tools/tours/add/`,
   `/tools/tours/:slug/` and `/tools/tours/join/:token/`, plus a card on
   `pages/tools/index.vue`.
3. Shared components in `app/frontend/frontend/components/Payouts/` so both routes are thin
   shells over a ledger id: `PayoutSummary`, `PayoutEntryList` + `PayoutEntryModal`,
   `PayoutParticipantList` + `PayoutParticipantModal`, `PayoutBalances`, `PayoutTransferList`.
4. Every amount renders through `toUEC`. Data comes from the orval hooks; refresh after a
   mutation via `refetch()` driven by the `useComlink` bus, as the missions pages do.
5. i18n keys under `nav.*`, `title.*`, `headlines.*`, `labels.*`, `actions.*`, `messages.*`,
   `empty.*`. Crowdin is not in use — all seven locales (`en de es fr it zh-CN zh-TW`) are
   written by hand, or the other six silently fall back to English. A route needs both a
   `nav.*` and a `title.*` entry.

### Phase 7 — Tests

1. `test/models/` for `tour`, `payout_ledger`, `payout_participant`, `payout_entry`.
2. `test/lib/payouts/settlement_test.rb` — the important one. `Σ net == 0`; a profit that does
   not divide evenly; a participant with no entries still taking a share; a pure-expense tour
   with no income; one participant; zero participants; a guest participant; and two runs over
   the same ledger producing identical transfers.
3. `test/integration/api/v1/` — one file per endpoint and verb, each declaring its `api_path`
   block. `setup` must `Flipper.enable("tour_payouts")`, as the event tests do for
   `fleet_mission_builder`.
4. `test/factories/` for each new model.
5. Frontend `*.spec.ts` beside `PayoutTransferList` and `PayoutBalances`. Unmount VTU wrappers
   in teardown — a leaked wrapper makes a later test assert against a second pinia store and
   pass either way.

## Intent Verification

- [ ] **An event can be given a set of users** — opening a ledger on a fleet event seeds
      participants from its non-withdrawn signups, and an organiser can add or remove people,
      including a guest with no account.
- [ ] **Every user can add entries of what they spent or took in** — a participant records an
      expense or income entry against themselves; an organiser can record one for anybody,
      including a guest.
- [ ] **At the end the site calculates a full payout list** — settling the ledger produces a
      list of transfers naming who sends what amount to whom, covering every participant with
      a non-zero balance in at most `n − 1` transfers.
- [ ] **The list balances** — the sum of every participant's net position is exactly zero, and
      settling the same ledger twice produces byte-identical transfers.
- [ ] **It works without a fleet** — a tour created at `/tools/tours/add/` can be joined
      through its invite link by a second account and settled the same way.

## Key files

| File | Role |
|------|------|
| `db/migrate/*` | The five new tables |
| `app/models/tour.rb` | Standalone owner, AASM lifecycle, invite token |
| `app/models/payout_ledger.rb` | Polymorphic subject, settle/reopen, participant seeding |
| `app/models/payout_entry.rb` | Typed, positive-amount ledger entry |
| `app/lib/payouts/settlement.rb` | Balances and min-cash-flow transfers |
| `app/policies/payout_ledger_policy.rb` | The one place the two owners diverge |
| `app/models/fleet_role.rb` | `PRIVILEGE_GROUPS` gains `"payouts"` |
| `config/feature_flags.yml` | `tour_payouts` |
| `db/data/*_grant_payout_privileges_to_existing_roles.rb` | Without it, existing fleets 403 |
| `config/routes/api/payouts_routes.rb` | Ledger children addressed by ledger id |
| `app/frontend/frontend/components/Payouts/` | Shared by both the event and tour pages |
| `app/frontend/shared/utils/I18nHelpers.ts` | `toUEC`, reused — not extended |

## Not in scope (deferred)

- **Weighted / joined-at shares** — the
  [issue comment](https://github.com/fleetyards/fleetyards/issues/2640#issuecomment-1666151888)
  asks for a late joiner to take a reduced share. Equal shares ship first; the participant row
  is where a weight would later go.
- **Live updates over ActionCable** — would pull in an asyncapi contract for a tool whose
  whole point is to settle at the end. The `useComlink` refetch covers the single-user case.
- **Notifying participants on settle** — a natural follow-up once the payout list exists.

## Discovery Log

- **2026-09-12** Phases 5-7 landed: policies, controllers, routes, jbuilder, the
  OpenAPI components and 93 request specs, plus the ledger UI on both surfaces and the
  seven locales. Three things the plan did not anticipate: a concern that registers its
  own `before_action` runs *before* the including controller's, which turned every 401
  into a 403 until the callbacks were declared explicitly; `current_resource_owner` is
  not reachable from a jbuilder view, so the invite token is rendered against a
  controller-set `@viewer`; and a guest participant has to omit `user` rather than emit
  null, because UserRef types it as an object.
- **2026-09-12** Phases 1-4 landed: tables, models, the settlement service with its
  invariant tests, the `tour_payouts` flag and the privilege backfill. The asyncapi cable
  schema had to be regenerated too — `fleetRole.resourceAccess` is an enum built from
  `FleetRole.all_available_privileges`, so a new privilege group makes every membership
  broadcast fail validation until `bin/generate-asyncapi` runs.
- **2026-09-12** Initial research and plan creation. Confirmed with the user: polymorphic
  owner shipping both surfaces at once, expenses-plus-income rather than cost-splitting, no
  currency column, and an explicit participant list that allows guests.

## Progress

- [x] Phase 1 — Schema
- [x] Phase 2 — Models
- [x] Phase 3 — Settlement service
- [x] Phase 4 — Permissions and the flag
- [x] Phase 5 — API
- [x] Phase 6 — Frontend
- [x] Phase 7 — Tests
