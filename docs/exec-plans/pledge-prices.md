# Pledge prices — a table for store prices, fed from UEX

Source: `GET https://api.uexcorp.uk/2.0/vehicles_prices/` (verified 2026-08-12).

## Goal

Give RSI pledge-store prices a relational home instead of a single scalar on
`models`, so that the figures we hold **none** of today — warbond, concierge and
in-package prices — have somewhere to live, and so a store price carries a
history rather than only its current value.

The pattern mirrors what in-game prices already do after `feat/power-distribution-ui`:
`item_prices` is the record and `models.price` the derived cache. Here
`pledge_prices` becomes the record and `models.pledge_price` stays the cache.

Non-goals, each for its own reason:

- **CCU prices.** A CCU price is keyed on a *pair* of models (from → to), so it
  fits neither this table nor `item_prices` without a second model reference. It
  also has no data source: UEX exposes no CCU endpoint (`vehicles_pledges`,
  `vehicles_pledge_prices`, `vehicles_prices_pledges` all 404, and the API docs
  list nothing pledge-related beyond `vehicles_prices`), and RSI's
  `TySkuUpgradeFragment` returns id, title, subtitle, slug, isWarbond and stock
  — no price. Scraping RSI's upgrade store is a separate project.
- **Package entities.** A package is a bundle with contents — a ship, a game
  package, insurance. UEX's `price_package` is not that; it is "what this ship costs
  when bought inside a package", which is a per-model figure and therefore a
  `kind` in this table.
- **`item_prices` and in-game pricing.** Untouched.
- **`model_upgrades.pledge_price`.** The two hand-entered kit prices stay where
  they are; folding them in is a follow-up at best.

## Where we are

| Holder | Meaning | Written by |
| --- | --- | --- |
| `models.pledge_price` `decimal(15,2)` | current standalone MSRP, excl. VAT | `Rsi::PledgeStoreLoader` from GraphQL `msrp / 100.0`, falling back to the held value when RSI omits `msrp` |
| `models.rsi_pledge_value` `integer` | the same figure in cents | same loader — a duplicate |
| `models.on_sale` `boolean` | RSI `purchasable` | same loader |
| `model_upgrades.pledge_price` | upgrade kits (2 rows locally) | admin form only |

Nothing holds warbond, concierge or package prices, and nothing holds a previous
price.

## What the feed gives us

786 rows over 260 vehicles. One row per `(vehicle, game_version)` — **it is a
history, not a snapshot**: 3 rows per vehicle on average, up to 6, spanning
versions up to `4.8.2`.

```json
{
  "id": 1, "id_vehicle": 107, "price": 210, "price_warbond": 0,
  "price_package": 0, "price_concierge": 0, "on_sale": 0, "on_sale_warbond": 0,
  "on_sale_package": 0, "on_sale_concierge": 0, "currency": "USD",
  "game_version": "4.0.2", "date_added": 1703566807,
  "date_modified": 1741107787, "vehicle_name": "Hurricane"
}
```

Fill rates, so the sparseness is on the record before anyone reaches for columns:

| Field | Rows non-zero | Distinct vehicles |
| --- | ---: | ---: |
| `price` | 779 (99%) | 255 |
| `price_warbond` | 147 (19%) | 95 |
| `price_package` | 76 (10%) | 30 |
| `price_concierge` | 37 (5%) | 29 |

`on_sale = 1` on 476 rows, `on_sale_warbond = 1` on 24.

## Three decisions before coding

### 1. UEX is not the source for the standalone price

Taking the newest UEX row per vehicle against our 240 `pledge_price` values, over
231 matched models:

| Relationship | Models | Reading |
| --- | ---: | --- |
| identical | 76 | agree |
| UEX ≈ ×1.071 | ~55 | UEX figure is tax-inclusive (Javelin ours $3000 vs $3213) |
| UEX = ×0.9 | 34 | UEX row is a sale or warbond price (Ironclad $600 vs $540) |

Ours comes from RSI's `msrp`, excl. VAT, which is what the ship page labels it as
("On Sale: $155 excl. VAT"). So **`models.pledge_price` stays RSI-fed and remains
what the card renders.** UEX's contribution is the kinds we have no other source
for, plus the history.

UEX standalone rows are still stored — a warbond price means nothing without the
standalone figure from the same row to discount against — but they carry
`source: :uex` and **must not be rendered beside the RSI figure**. Two
contradictory prices on one card is exactly the bug this branch just fixed for
the in-game price.

Do not normalise the ~7.1% uplift away. Whether it is VAT, a regional rate, or
UEX storing gross for some entries is unresolved, and dividing by a guessed
constant would launder the uncertainty into a number that looks exact.

### 2. A table, not four more columns on `models`

`pledge_prices`:

| Column | Type | Note |
| --- | --- | --- |
| `model_id` | uuid, not null | |
| `kind` | integer, not null | enum `standalone: 0, warbond: 1, concierge: 2, package: 3` |
| `price` | decimal(15,2), not null | |
| `currency` | string, default `"USD"` | the feed states it per row |
| `game_version` | string | null for a row that is not version-tagged |
| `on_sale` | boolean, default false | the per-kind flag, not the model-level one |
| `source` | integer, not null | enum `uex: 0, rsi: 1, manual: 2` |
| `external_id` | integer | UEX row `id`, for re-identification |
| `source_updated_at` | datetime | from `date_modified` |

Unique index on `(model_id, kind, game_version, source)`; index on `model_id`.

Three reasons over columns: the kinds are sparse (a package price exists for 30
of 246 models, so three mostly-null columns), history is the point and columns
cannot hold it, and a fifth kind later is a row rather than a migration.

### 3. Matching reuses `Uex::VehicleMatcher`

It already resolves every priced vehicle in the in-game sync with 8 `MAPPINGS`
entries. This feed covers 260 vehicles against that sync's 179, so expect fresh
misses — reuse the `GithubIssueCreator` path so they surface as an issue rather
than silence.

## Steps

### Step 1 — migration + `PledgePrice`

Model with the two enums (`validate: true`, as `ItemPrice` does), `belongs_to
:model`, `validates :price, presence: true`. On `Model`: `has_many
:pledge_prices, dependent: :destroy` plus a `current_pledge_prices` scope that
picks the newest `game_version` row per kind.

### Step 2 — `Uex::Client#vehicle_pledge_prices`

One more method over `get("vehicles_prices")`. The existing 403-without-User-Agent
and `status != "ok"` guards apply unchanged.

### Step 3 — `Uex::PledgePriceSyncer`

Per vehicle row, resolve the model through the matcher, then emit up to four
desired rows — one per non-zero `price*` field, carrying that kind's `on_sale*`
flag. Upsert on the unique key; count `created` / `updated`.

**History is append-only: never delete a row because the feed stopped mentioning
it.** That inverts `Uex::PriceSyncer`'s reconciliation deliberately — there, a
vanished row means a shop stopped stocking the ship; here it means an old patch
scrolled out of the window, and the price was still true when it was true. Which
also means none of the retention/truncation guarding needs porting: an empty feed
can create nothing, and creates no deletions to guard against. Keep the
`require_rows` guard anyway so a 200-with-no-data still raises rather than
reporting a clean no-op run.

### Step 4 — job, import type, schedule

`Loaders::UexPledgePricesJob` mirroring `Loaders::UexPricesJob`:
`Imports::UexPledgePricesImport` STI class, added to
`Shared::V1::Schemas::Enums::ImportTypeEnum`, then `./bin/generate-schema`, plus
a jbuilder partial under `app/views/api/v1/imports/uex_pledge_prices_imports/` —
without both, `ImportTest`'s "every broadcasting import type renders its jbuilder
partial" fails.

Schedule **weekly**, not daily: store prices move at patch and sale cadence, and
the feed is version-tagged rather than live. `'0 6 * * 0'` in
`config/sidekiq_schedule.yml`, queue `loaders`.

### Step 5 — API and UI (defer until someone wants the numbers)

Serialise a `pledgePrices` block on the model via `api_components` (never
`schema.yaml` directly), omitting the field when empty rather than nulling it.
The natural surface is a Pledge modal as a sibling to the Availability modal
reached from the same Base card — standalone / warbond / concierge / package as
rows, previous versions behind them — reusing the classes the availability modal
now establishes. Not worth building before the table has data.

### Step 6 — Verify

Live run in development; assert idempotency on a second run (`created=0
updated=0`); expect roughly 255 standalone / 95 warbond / 30 package / 29
concierge rows across matched models, and check the unmatched list is either
empty or lands in `MAPPINGS`.

## Open questions

- **`rsi_pledge_value`** duplicates `pledge_price` in cents. Drop it in a
  follow-up; it is unrelated to this table but adjacent enough to name here.
- **Sale flags.** `models.on_sale` (RSI `purchasable`) and a row's `on_sale` mean
  different things — "buyable right now" vs "this price was a sale price". Do not
  let the second overwrite the first.
- **CCUs remain unsolved and unblocked by this plan.** If a CCU tool is the real
  goal, the first question is where the prices come from, not where they go.
