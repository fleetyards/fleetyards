# Stats Expansion — Exec Plan

## Current State

Three stats surfaces exist, all built from live table counts:

- **Global** (`Api::V1::Stats::BaseController`, `/stats`): quick-stats (10 tiles) plus
  models-per-month, models-by-size / -production-status / -manufacturer / -classification,
  components-by-class, vehicles-by-model, vehicles-per-month, ships-of-the-month.
- **Hangar / Fleet** (`HangarStatsController`, `FleetStatsController`, plus their
  `Public::` counterparts): 16 metrics and the same four pie charts.
- **Rollups** (`MetricsJob`, daily at 1:00): Registrations, Activity, Models, Fleet,
  Vehicle, Vehicle Wish, Visits, Ship of the Month, API usage. Only Ship of the Month
  and API usage carry `dimensions`.

Everything currently shown is a snapshot of *now*. Three data sources are being
overwritten or purged before anything reads them:

| Source | Overwritten by | History kept |
|---|---|---|
| Ahoy `$view` events (carry `/ships/<slug>/` in `properties->>'page'`) | `Cleanup::VisitsJob`, monthly, deletes visits older than 1 month | only a monthly total, no per-page dimension |
| `models.on_sale` | every RSI sale sync; fires a notification (`model.rb:454`) and moves on | none — `on_sale` is **not** in the `has_paper_trail only:` list |
| `item_prices` (UEX) | `Loaders::UexPricesJob` 5:00 and `Loaders::UexCommodityPricesJob` 5:30, daily, production only | none — `persist_prices` is a snapshot; `time_range` is a rental attribute, not a timestamp |
| `model_builds` | `ModelBuild::BUILDS_RETAINED = 3` prunes older versions | last 3 patches per environment |

By contrast `models.pledge_price` and `models.price` **are** paper-trailed, so pledge
price history already exists (698 price-bearing `Model` versions in the 2026-08-13 dump)
and is shown nowhere.

## Goal

1. Start persisting the four sources above before more history is lost.
2. Add three aggregate charts that need no new collection at all.
3. Surface the per-model history on a new ship sub-page.

Decisions taken up front:

- **Per-model history lives on the ship detail page**, as a new `history/` sub-page
  next to `images/`, `videos/` and `viewer/`. The global `/stats` page gets only the
  aggregates.
- **Price history granularity**: commodities per terminal (~5k rows/day), components and
  equipment as a daily per-item aggregate (min/max/avg buy and sell).

## Ordering

Phases 1–5 come first and are independent of each other. Every day without them is
history that cannot be reconstructed. Phases 6–8 read what is already stored and can
follow at any time.

**Status:** phases 1–6 are shipped, so nothing is being lost any more. What remains reads
what is now stored (7, 8, 9) or waits on a feature flag to open (10–12). Phase 7 comes
before phase 8: the ship history page has four panels and the pledge price series is one
of them, so building the page first would mean building it twice.

Each phase is one PR. All API phases follow the workflow in AGENTS.md: integration test
first, then model, controller, policy, route, `app/api_components/` component, then
`bundle exec standardrb --fix`, `./bin/generate-schema`, Orval regeneration, `bin/rails test`.

---

## ~~Phase 1: Ship view rollup~~ ✅

Shipped in #4698, as written.

One thing turned out weaker than the plan assumed: excluding opted-out users is
belt-and-braces, not the safeguard it reads as. `Ahoy.exclude_method` already refuses to
*record* an objecting user, so the filter only covers rows written before they objected.
It is written as `user_id IS NULL OR user_id NOT IN (...)` because `NOT IN` alone drops
every anonymous view along with them -- `NULL NOT IN (…)` is `NULL`, and anonymous is most
of the traffic.

- [x] Add a `Ship Views` rollup to `MetricsJob`, dimension = model slug:
      filter `name: "$view"` and `properties->>'page' LIKE '/ships/%'`, group on a SQL
      expression that extracts the slug, `column: :time`, `interval: "day"`
- [x] Pass `dimension_names: ["model_slug"]` explicitly — the gem's
      `determine_dimension_name` only accepts a bare `\A\w+\z` tail, which a substring
      expression is not
- [x] Exclude opted-out users the same way the cleanup job does
      (`Ahoy::Visit.without_users(tracking_blocklist)` / `users.tracking = false`)
- [x] Add a `trending-ships` endpoint on the global stats controller reading the last
      30 days of that rollup, joined back to `Model` by slug so a renamed or hidden ship
      drops out
- [x] Frontend: bar chart panel on `/stats`, wired into `csvCharts`

### Traps
- The rollups gem recomputes from `max_time..`, i.e. only the newest stored interval
  onward. That is what makes a daily interval safe next to a monthly purge — a monthly
  interval would recompute a partially purged month down to a wrong number.
- `Rollup.series` does not filter dimensions. Dimension rollups have to be read with a
  direct `Rollup.where(name:, interval:, dimensions:)` query, the way `ships_of_the_month`
  already does.
- Ahoy's time column is `time`, not `created_at`; the gem defaults to `created_at`.

### Files
- `app/jobs/metrics_job.rb`
- `app/controllers/api/v1/stats/base_controller.rb`
- `config/routes/api/v1_routes.rb`
- `app/api_components/v1/schemas/` (chart point list component)
- `test/integration/api/v1/stats_trending_ships_test.rb`
- `test/jobs/metrics_job_test.rb`
- `app/frontend/frontend/pages/stats.vue`

---

## ~~Phase 2: Sale history~~ ✅

Shipped in #4700.

The plan offered a choice on the ships that were already on sale: seed them, or leave them
out. They are seeded, and the reason is stronger than "otherwise the data starts late" --
with no open row the flag's *next* flip has nothing to close, so the sale running that day
would vanish entirely rather than merely start late. Their `started_at` is the migration's
run time, which under-reports how long those first sales ran and is wrong in that one
direction only.

- [x] Migration: `model_sales` with `model_id`, `started_at`, `ended_at` (nullable),
      unique index on `(model_id, started_at)`, index on `started_at`
- [x] `ModelSale` model with `belongs_to :model`, an `ongoing` scope (`ended_at IS NULL`)
      and a `duration` reader
- [x] Hook the existing `saved_change_to_on_sale?` callback: opening a sale creates a row,
      closing it stamps `ended_at` on the open row. Do **not** add `on_sale` to the
      paper_trail `only:` list — a dedicated table is queryable, a JSON diff is not
- [x] Model readers: `last_sale`, `sales_count(period)`, `average_days_between_sales`
- [x] Endpoint `GET /v1/models/:slug/sales` returning the list plus those derived figures

### Traps
- A sale that is already open when this ships has no `started_at`. Seed the initial rows
  from the 79 models currently flagged `on_sale` with `started_at` = deploy time and a
  comment saying so, or leave them out — do not backdate a guess.
- Nothing reconstructs past sales. This phase only starts the record.

### Files
- `db/migrate/*_create_model_sales.rb`
- `app/models/model_sale.rb`, `app/models/model.rb`
- `test/factories/model_sales.rb`, `test/models/model_sale_test.rb`
- `app/controllers/api/v1/models_controller.rb`, `config/routes/api/v1_routes.rb`
- `app/api_components/v1/schemas/model_sale.rb`, `.../model_sales_list.rb`
- `test/integration/api/v1/models_sales_test.rb`

---

## ~~Phase 3: Wishlist rollup per model (hype curve)~~ ✅

Shipped in #4702, with one deliberate departure.

The dimension went on **its own rollup name** (`Vehicle Wish by Model`) rather than onto
the existing `Vehicle Wish`. Under one name and interval the table would hold both a total
row and up to 243 per-model rows, and every reader of the plain series would have to know
to ask for the empty dimensions.

The plan's reason for keeping the dimensionless rollup was also wrong: the `wishlistsCount`
tile does a live `Vehicle.where(wanted: true).count`, not a rollup read. **Nothing** reads
that rollup. It stays anyway -- twelve years of history nobody can reconstruct.

- [x] Add `model_id` as a dimension to the existing `Vehicle Wish` rollup in `MetricsJob`
      (`Vehicle.visible.wanted.where(loaner: false).group(:model_id).rollup(...)`)
- [x] Keep the existing dimensionless rollup as well — the global
      `wishlists_count` tile reads it, and it is 12 years of history
- [x] Endpoint: wishlist additions per month for one model, plus a global
      "biggest movers this month" chart
- [x] Frontend: line panel on the ship history page, mover chart on `/stats`

### Traps
- The rollup counts `created_at`, so it measures *additions*, not the standing total.
  Label it accordingly ("new wishlist entries"), or the chart reads as a decline whenever
  growth merely slows.
- 243 visible models × months is small, but the dimension turns one row per month into
  up to 243. Confirm `rollups` stays sane after the first run.

### Files
- `app/jobs/metrics_job.rb`
- `app/controllers/api/v1/stats/base_controller.rb`, `config/routes/api/v1_routes.rb`
- `test/jobs/metrics_job_test.rb`, `test/integration/api/v1/stats_wishlist_movers_test.rb`

---

## ~~Phase 4: Price history (UEX snapshot)~~ ✅

Shipped in #4704. The daily UEX sync overwrites `item_prices` in place, so the snapshot
had to come before the next overwrite.

**The framing here was wrong, and the correction matters for what gets built on top.**
This phase was written as a trading feature — price history, movers, a chart traders read.
Fleetyards is not where people go to look up commodity prices; UEX and its like own that,
and a commodity chart on `/stats` sat among ship charts saying nothing to the audience
reading them. The movers panel and its endpoint were removed again after they shipped.

What the collection is actually for, and why it stays running:

- **Ship prices.** `Uex::PriceSyncer` is `ITEM_TYPE = "Model"` — it prices ships, purchase
  and rental, per terminal. That is a Fleetyards question, and it is in the same snapshot.
- **Inventory value.** Ledger entries in `fleet_logistics` and `hangar_inventories` point
  at `Commodity`, `Component` or `Equipment` through a polymorphic `item`. What a fleet's
  cargo is worth, and what it was worth last month, needs exactly this history. There the
  commodity price is the means rather than the point. See phase 11.

Two corrections of fact from building it, kept because they change the design:

- The second syncer prices **ships**, not components and equipment. Components and
  equipment carry prices, but hand-entered ones no daily sync touches, so nothing about
  them is being lost. That removed the reason for splitting the storage: both synced types
  are recorded per terminal in one `item_price_snapshots` table.
- Retention is 24 months for everything, not 12 for commodities and forever for aggregates.

- [x] Migration: one `item_price_snapshots` table — polymorphic `item`, `location`,
      `price_type`, `time_range`, `price`, `recorded_on`, unique index on all of them with
      `nulls_not_distinct` (only rentals carry a `time_range`)
- [x] Write the snapshot from the syncers (`Uex::CommodityPriceSyncer`,
      `Uex::PriceSyncer`) after a successful run, keyed on `recorded_on` so a re-run the
      same day upserts instead of duplicating
- [x] Retention: 24 months for everything, via a monthly `Cleanup::PriceSnapshotsJob`
- [x] Endpoint: price history for one commodity
- [ ] ~~A global "biggest price movers" chart~~ — built, then removed again as off-topic
- [ ] ~~Frontend: history panel on the commodity detail view~~ — there is no public
      commodity page; `resources :commodities` is `only: [:index]` and the frontend has no
      commodities route at all. The endpoint waits for one.

### Traps
- Both loader jobs are `enabled: <%= Rails.env.production? %>`. Locally nothing populates
  `item_prices` (0 rows in the dump), so the snapshot writers need unit tests against
  fixtures — a manual local check proves nothing.
- The snapshot must not run inside the syncer's own transaction over `persist_prices`, or
  a failed removal pass rolls the day's history back with it.
- Production has ~2,900 deduped commodity price locations on the first page of 100 items
  alone. Verify the real row count on live before choosing the retention window.

### Files
- `db/migrate/*_create_commodity_price_snapshots.rb`, `*_create_item_price_snapshots.rb`
- `app/models/commodity_price_snapshot.rb`, `app/models/item_price_snapshot.rb`
- `app/lib/uex/commodity_price_syncer.rb`, `app/lib/uex/price_syncer.rb`,
  `app/lib/uex/price_snapshot.rb`
- `app/jobs/cleanup/price_snapshots_job.rb`, `config/sidekiq_schedule.yml`
- `test/lib/uex/*_test.rb`, `test/integration/api/v1/commodities_price_history_test.rb`

---

## ~~Phase 5: Patch change log~~ ✅

Shipped in #4705.

Of the two options for the structured facts -- record a presence change, or normalise
before comparing -- neither was taken: they are excluded outright, and the diffable list is
**derived** (`FACTS - STRUCTURED_FACTS - [:ground]`) so a numeric fact added later is
picked up without anyone remembering to say so.

The three retained builds are deliberately **not** walked backwards on deploy. Re-deriving
old diffs from rows that may since have been re-parsed would date them wrong, and a gap
beats an invented history.

- [x] Migration: `model_build_changes` — `model_id`, `environment`, `from_version`,
      `to_version`, `field`, `old_value`, `new_value`, `recorded_at`, unique index on
      `(model_id, environment, to_version, field)`
- [x] Compute the diff when a new build lands, over `ModelBuild::FACTS`, and write one row
      per changed field
- [x] Endpoints: changes for one model, and a global "what this patch changed" list
- [x] Frontend: change table on the ship history page, patch summary panel on `/stats`

### Traps
- Five of the `FACTS` columns are YAML-serialized (`cargo_holds`, `quantum_fuel_tanks`,
  `hydrogen_fuel_tanks`, `external_fuel_tanks`, `refuel_boom`) and two are `jsonb`
  (`hull_parts`, `hull_doors`, `signature_cross_section`). Comparing those with `!=`
  reports a change on every re-parse. Diff numerics only in the first pass and store the
  structured ones as a presence change, or normalize before comparing.
- A re-parse of the same dump quietly changes values without a version bump — see the
  `sc_data parsed tree drift` note. Key the diff on `(from_version, to_version)`, so a
  same-version re-load updates rather than appends.
- The local dump holds exactly one build version, so this phase cannot be verified against
  real deltas locally. Build the fixtures deliberately.

### Files
- `db/migrate/*_create_model_build_changes.rb`
- `app/models/model_build_change.rb`, `app/models/model_build.rb`
- the sc_data models loader that writes builds
- `test/models/model_build_change_test.rb`,
  `test/integration/api/v1/models_changes_test.rb`

---

## ~~Phase 6: Aggregate charts with no new collection~~ ✅

Shipped in #4707.

The index this phase expected was not needed. Measured against the full dump rather than
assumed: **87ms** for the wishlist grouping and **68ms** for the paints grouping over 1.57M
vehicles, both parallel sequential scans. An index on that table costs writes on every
hangar change, so none was added.

Two things came out of looking at the rendered page, which is worth doing before calling
one of these done:

- `name_with_model` made the paint chart say the ship twice -- "Carrack - Carrack
  Expedition". Globally only 14 of 1,923 paints are named after their ship, but they are
  six of the eight most-used, so they dominate exactly this chart.
- The page had grown full-width panels among paired rows. Everything is two halves now.

The wish-to-own floor is 100 owned, picked from the distribution rather than guessed: the
median model holds 2,200 and the tenth percentile 744, so it excludes only ships nobody has.

- [x] **Top wishlist ships** — `stats/wishlist-by-model`, the mirror of the existing
      `vehicles_by_model`:
      `Vehicle.visible.wanted.where(loaner: false).joins(:model).group("models.name").count`.
      457,593 wishlist rows exist; today only their total count is exposed.
- [x] **Wish-to-own ratio** — `stats/wish-to-own-ratio`, wishlist count over purchased
      count per model, minimum-sample floor so a model with three entries cannot top the
      chart. Separates a dream ship from a volume ship, and is not reachable by sorting
      the ship list.
- [x] **Most popular paints** — `stats/top-paints`, grouping `vehicles.model_paint_id`
      (51,271 vehicles carry one, against 1,923 paints on 220 models). Add a paint
      adoption tile (share of vehicles with a paint set, ~3.3%).
- [x] Frontend: three panels on `/stats`, each registered in `csvCharts` so the panel
      export and the page export stay in sync

### Traps
- All three group on `Vehicle`, which is 1.57M rows. `vehicles_by_model` gets away with a
  plain group because it is capped with `.take(10)` after the fact — check the plan for
  each new query and add an index if the group is not already covered
  (`index_vehicles_on_model_id_and_id` covers the model grouping, nothing covers
  `model_paint_id`).
- Exclude loaners everywhere. 598,245 of the 1.57M vehicles are loaners and would swamp
  every ranking.

### Files
- `app/controllers/api/v1/stats/base_controller.rb`, `config/routes/api/v1_routes.rb`
- `app/api_components/v1/schemas/` chart components
- `test/integration/api/v1/stats_wishlist_by_model_test.rb`,
  `stats_wish_to_own_ratio_test.rb`, `stats_top_paints_test.rb`
- `app/frontend/frontend/pages/stats.vue`

---

## Phase 7: Pledge price history from paper_trail

No new collection — `pledge_price` and `price` are already in `Model`'s paper_trail
`only:` list.

- [ ] Reader on `Model` that walks `versions` and extracts `pledge_price` / `price`
      changes into a `(changed_at, from, to)` series
- [ ] Endpoint `GET /v1/models/:slug/price-history`
- [ ] Global "biggest price increases" chart for the last 12 months

### Traps
- This reads `object_changes` JSON across 8,498 `Model` versions in a 612k-row table. Do
  not filter with a `LIKE` over `object_changes::text` in the endpoint — resolve the
  series in one query and cache it, or denormalize into a small table if the chart is slow.
- Only changes since paper_trail started tracking the column exist. State the coverage in
  the UI rather than implying a complete history.

### Files
- `app/models/model.rb`
- `app/controllers/api/v1/models_controller.rb`, `config/routes/api/v1_routes.rb`
- `app/api_components/v1/schemas/model_price_history.rb`
- `test/integration/api/v1/models_price_history_test.rb`

---

## Phase 8: Ship history sub-page

One page assembling phases 2, 3, 5 and 7 for a single ship.

- [ ] Route `history/` in `app/frontend/frontend/pages/ships/[slug]/routes.ts`,
      name `ship-history`, `meta.customTitle`
- [ ] Page component receiving `:model` from the `[slug].vue` router-view, holding four
      panels: sale history, pledge price history, wishlist trend, patch changes
- [ ] Entry in the `BtnDropdown` on `ships/[slug]/index.vue` (~line 395), next to the
      images and videos entries
- [ ] Title and breadcrumbs follow the sibling pages, not the route-meta mechanism:
      `customTitle: true` on the route, then `useMetaInfo()` with a `title.shipHistory`
      key and a `BreadCrumbs` trail, exactly as `images.vue` does
- [ ] Add `ship-history` to the route-name list in `components/Navigation/index.vue:71`
      if the nav should stay highlighted — note `ship-viewer` is deliberately absent
      from that list, so check which behaviour is wanted
- [ ] Empty states per panel: a ship with no recorded sale, no price change and no patch
      delta is the normal case in the first months

### Files
- `app/frontend/frontend/pages/ships/[slug]/routes.ts`, `history.vue`
- `app/frontend/frontend/pages/ships/[slug]/index.vue`
- `app/frontend/frontend/components/Navigation/index.vue`
- `app/frontend/translations/*`

---

## Phase 9: Ship of the Month history

- [ ] Drop the `where("time > ?", 1.year.ago)` clause in `ships_of_the_month` and expose
      the full series with a range parameter (16 monthly rows exist today)
- [ ] Add a year interval to the Ship of the Month rollup in `MetricsJob` for a
      "ship of the year" tile

### Files
- `app/controllers/api/v1/stats/base_controller.rb`, `app/jobs/metrics_job.rb`
- `test/integration/api/v1/stats_ships_of_the_month_test.rb`

---

## Phase 10: Event stats (`fleet_mission_builder`)

The tables are empty because the flag is off, not because the data would be thin. The
schema already records almost everything worth asking, and event stats are fleet-scoped —
they belong on the fleet, not on the public `/stats` page.

### Already recorded, needs only aggregation

- **Signup funnel** — `fleet_event_signups.status` covers the five states in
  `FleetEventSignup::STATUSES` (`confirmed`, `tentative`, `interested`, `pending`,
  `withdrawn`). Withdrawal rate per event and per fleet falls straight out of it.
- **Lead time** — `signups.created_at` against `fleet_events.starts_at` answers "how long
  before an event do people commit", and `confirmed_at - created_at` measures how quickly
  officers work through a `confirmation_required` queue.
- **Reliability per member** — signups carry `fleet_membership_id`, so attendance,
  no-shows and withdrawals are countable per member over time. Sensitive by nature:
  officer-only, and never on a public surface.
- **Requested versus fielded ships** — the demand side is `fleet_event_ships`
  (`classification`, `focus`, `min_size`/`max_size`, `min_cargo`, `min_crew`) plus
  `fleet_event_ship_models`; the supply side is `signups.vehicle_id`. The gap between
  them is the most useful number the feature can produce: which roles a fleet cannot
  crew, and which requested models nobody owns.
- **Slot fill rate** — `fleet_event_slots` is polymorphic over teams and ships and points
  at `model_position_id`, so an empty seat is identifiable by position. "Turrets go unmanned"
  is a real finding a fleet can act on.
- **Utilisation** — `max_attendees` against `signups_count`.
- **Category and scenario mix** — the eight `FleetEvent.categories`, plus `scenario`,
  `recurring` and `visibility`.
- **Recurrence health** — `fleet_event_occurrence_states` carries `cancelled_at`,
  `locked_at` and a per-date `status`, so a recurring series can be measured occurrence
  by occurrence rather than as one event.
- **Discord reach** — `discord_synced_at` / `discord_event_id` coverage shows how many
  events actually made it to Discord.

### Not recorded — collect from the start

- ~~**State transition times.**~~ ✅ `aasm column: :status, timestamps: true` writes a
  `<state>_at` column only where one exists, and `fleet_events` had none — no `open_at`,
  no `locked_at`, no `completed_at`. So "how far ahead are events published", "how long
  before start do signups lock" and completion rate over time were all unanswerable, and
  unanswerable retroactively.
  Done in `AddStatusTimestampsToFleetEvents` (#4696): one column per non-initial target state
  (`open_at`, `locked_at`, `active_at`, `completed_at`, `cancelled_at`), matching what
  `fleet_memberships` and `imports` already carry, plus a `published_at` that is stamped
  once — `open_at` moves on every unlock, which is the wrong reading for a lead time.
  Recurring events lock per occurrence and `fleet_event_occurrence_states` already had
  `locked_at` and `cancelled_at`, so nothing was added there; whether an occurrence needs
  its own `active_at`/`completed_at` is a product question for when the flag opens.
  The columns are deliberately **not** in the API payload or `ransackable_attributes` yet
  — the aggregation step below is what exposes them.
- **A frozen roster.** Signups are mutable rows. A member who withdraws after the event
  leaves no trace of having attended, so an attendance history rewrites itself. If
  post-hoc attendance matters, snapshot the roster when the event completes.

### Files
- `db/migrate/*_add_status_timestamps_to_fleet_events.rb`
- `app/models/fleet_event.rb`, `app/models/fleet_event_signup.rb`
- `app/controllers/api/v1/fleet_stats_controller.rb`, `config/routes/api/fleets_routes.rb`
- `test/integration/api/v1/fleets_stats_events_test.rb`

---

## Phase 11: Inventory stats (`fleet_logistics`, `hangar_inventories`, `ship_inventories`)

Inventories are an append-only ledger, not a stock table: `InventoryLedgerEntry`
has `entry_type` (`deposit` / `withdrawal`), and `InventoryStockItem` is a computed
rollup with `net_quantity`, `entries_count` and `last_entry_at` — the sum is literally
`CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END`. That means **the time series
already exists**, for free, without any new collection. It is the one feature in this plan
whose history is not being thrown away.

### Already recorded

- **Stock over time** per position, from the ledger alone. No snapshot needed to plot it.
- **Throughput** — deposits against withdrawals per period; for fleet inventories per
  member via `member_id` / `added_by`, which shows who actually supplies the org.
- **Category and unit mix** — the seven `InventoryLedgerEntry::CATEGORIES`, and the
  SCU-versus-pieces split that `UNITS_BY_CATEGORY` enforces.
- **Quality distribution** — `quality` runs 0–1000, so refinement grades of mined ore
  are already in there.
- **Value in aUEC** — entries link to `Commodity`, `Component` or `Equipment` through the
  polymorphic `item`, and those items are priced by the UEX sync. An inventory's current
  worth is a join away; a *historical* worth needs Phase 4's price snapshots, which is a
  good reason to do Phase 4 first.
- **Ship cargo utilisation** — `inventories.vehicle_id` binds an inventory to one vehicle,
  so cargo aboard against the model's `cargo` (or its `cargo_holds` capacity) gives
  "this Caterpillar is 40% loaded". This is the stat the `ship_inventories` flag exists for.
- **Aggregate, public-safe rankings** — most-stocked commodities across all fleets, without
  naming any fleet.

### Traps

- `InventoryStockItemChange` renames or recategorises **every entry of a position at once**,
  as a single bulk `UPDATE` that skips validations. A stock chart built from the ledger is
  therefore rewritable after the fact — a rename in March silently moves January's volume
  to the new name. If a stable history matters, snapshot daily stock the same way as prices.
- There is no reversal-entry convention, so a deleted entry rewrites the past too.
- Volume today is nine fleet inventories with eleven entries and one personal inventory
  (one of which is vehicle-bound). Enough to build against, nowhere near enough to judge
  whether a chart reads well. Design against fixtures.

### Files
- `app/models/concerns/inventory_ledger_entry.rb`, `app/models/inventory_stock_item.rb`
- `app/controllers/api/v1/` inventory stats controller
- `test/integration/api/v1/` inventory stats tests

---

## Phase 12: Mission template stats

`missions` are templates — title, `category`, `scenario`, teams, slots, ship requirements —
that events reuse through `fleet_events.mission_id`. Small surface, but it answers which
templates a fleet actually runs.

- [ ] Runs per template, average signups per run, completion rate per template
- [ ] Ship requirements aggregated across a fleet's templates, against what the fleet owns
      — the same demand-versus-supply comparison as Phase 10, but for the plan rather than
      the single event
- [ ] Archived templates (`archived_at`) excluded from every ranking, counted separately

### Files
- `app/models/mission.rb`, `app/controllers/api/v1/fleet_stats_controller.rb`
- `test/integration/api/v1/fleets_stats_missions_test.rb`

---

## Sequencing note for phases 10–12

Only one item here is time-critical: the missing event status timestamps in phase 10.
Everything else reads data that either already exists (inventories) or does not exist yet
because the flag is closed (events, missions), and can be built whenever the features open.
The event timestamp migration should land **before** `fleet_mission_builder` is switched on
for anyone, because from that moment on every unrecorded transition is permanently gone.
