# UEX price sync — fill `item_prices` from uexcorp.space

Source: <https://uexcorp.space/api/documentation/> (API 2.0, base
`https://api.uexcorp.uk/2.0/`).

## Goal

Populate `item_prices` for `Model` records from a daily UEX sync, so the ship
page's Base card can show real buy and rental locations. Today the table is
empty everywhere — 0 rows locally, 0 availability across all 243 production
models — because `PrefillItemPrices` (`db/migrate/20240327160635`) sourced from
`CommodityPrice`/`ShopCommodity`, which were tableless and have since been
deleted. That migration was removed in `ca764abcf`.

Non-goals: components, paints, modules and upgrades (the `item_prices` table is
polymorphic and UEX has item prices too, but ships first); commodity/trade data;
any UI beyond what already reads `model.availability`.

## What the API gives us

Verified against the live API on 2026-08-11. **No authentication required** for
the bulk endpoints — a bearer token is only needed for the write/user endpoints.
A `User-Agent` header *is* required; without one the API returns 403.

Limits are generous relative to this job: 172,800 requests/day, 120/minute. The
whole sync is 3 requests.

| Endpoint | Rows | Shape |
| --- | --- | --- |
| `/vehicles/` | 280 | `id`, `name`, `name_full`, `slug`, `uuid`, … |
| `/vehicles_purchases_prices_all/` | 288 | `id`, `id_vehicle`, `id_terminal`, `price_buy`, `vehicle_name`, `terminal_name`, `date_modified` |
| `/vehicles_rentals_prices_all/` | 344 | `id`, `id_vehicle`, `id_terminal`, `price_rent`, `vehicle_name`, `terminal_name`, `date_modified` |
| `/terminals/` | 826 | `name`, `nickname`, `type`, `city_name`, `planet_name`, `space_station_name`, `star_system_name`, `contact_url`, … |

Purchases span 179 vehicles across 7 terminals; rentals 49 vehicles across 32.

## Three decisions to make before coding

### 1. `price_buy` maps to our `sell`, not `buy`

Ours is shop-perspective: `ItemPrice#sell?` means *the shop sells it*, which is
what `Model#sold_at` selects and what the UI labels "Sold at?". UEX's
`vehicles_purchases_prices` is player-perspective — what the player pays.

So **UEX purchase → `price_type: :sell`**. Getting this backwards silently
empties `soldAt` while filling an unused `boughtAt`. The deleted migration had
it right (`CommoditySellPrice → sell`); worth a test asserting it.

### 2. Rentals have no duration, but we require one

UEX carries exactly one rental row per `(vehicle, terminal)` — 344 rows, 344
distinct pairs, zero duplicates. There is no period field. Our model has
`validates :time_range, presence: true, if: -> { rental? }` with an enum of
`1-day` / `3-days` / `7-days` / `30-days`.

Evidence that it is the **1-day** price — rent as a share of purchase, same
vehicle:

| Vehicle | Rent | Buy | % |
| --- | ---: | ---: | ---: |
| M50 | 37,485 | 1,499,400 | 2.50% |
| 300i | 34,398 | 1,375,920 | 2.50% |
| 600i Explorer | 680,793 | 27,231,800 | 2.50% |
| Constellation Andromeda | 254,016 | 9,652,610 | 2.63% |
| Avenger Titan | 27,165 | 1,290,370 | 2.11% |
| Mustang Alpha | 9,639 | 610,470 | 1.58% |

A tight cluster at ~2.5% is consistent with a single fixed duration, and in game
the 1-day rate sits in that band. **Recommendation: store `1-day`.**

**Confirmed 2026-08-11** against an in-game rental board for the Avenger Titan,
which prices all four durations at every terminal:

| 1 day | 3 day | 7 days | 30 days |
| ---: | ---: | ---: | ---: |
| 27,165 | 71,308 | 142,616 | 509,344 |

UEX's `price_rent` of 27,165 is the 1-day figure, so `RENTAL_TIME_RANGE = "1-day"`
is right and no relaxed validation is needed. The multipliers are 1× / 2.63× /
5.25× / 18.75×, i.e. longer rentals are discounted rather than linear — had we
guessed 30-day, the figure would have been wrong by 18.75×, not the ~30× assumed
above.

UEX carries only the 1-day rate, so the other three durations are simply absent
from the feed. `ItemPrice#time_range` already enumerates all four, so a future
source could add them without a migration.

The longer periods are a pure function of the 1-day price — the per-day rate
steps down in eighths, and the ladder reproduces all three in-game figures to the
credit:

| Period | Per-day discount | Total multiplier | Predicted | In game |
| --- | ---: | ---: | ---: | ---: |
| 1 day | 1 | 1× | 27,165 | 27,165 |
| 3 day | 7/8 | 2.625× | 71,308 | 71,308 |
| 7 days | 3/4 | 5.25× | 142,616 | 142,616 |
| 30 days | 5/8 | 18.75× | 509,344 | 509,344 |

**Decision: do not store the derived three.** They add no information, quadruple
the rental rows, and — since `item_prices` has no sourced-vs-derived flag — would
look exactly as authoritative as the figures UEX actually publishes, so a rebalance
of the ladder would go unnoticed. The ladder is also only confirmed against one
ship. If the Base card ever shows a duration breakdown, derive it at render time
from the 1-day row.

### 3. Eight ships need a manual mapping

Matching UEX vehicles to our `Model` records, measured over the 179 vehicles
that actually carry a price:

| Strategy | Matched |
| --- | ---: |
| `slug` (ours is already UEX's format — both use `orig-100i`) | 105 |
| then `name` / `name_full`, case-insensitive | 66 |
| **unmatched** | **8** |

The stragglers: A2 / C2 / M2 Hercules Starlifter, Ares Inferno Starfighter,
Ares Ion Starfighter, C8R Pisces Rescue, Nova Tank, San tok.Yāi.

That is the same shape of problem `loaner_loader.rb` and `modules_importer.rb`
already solve with a constant mapping hash, and the repo has
`resolve-loaners-import` / `resolve-modules-import` skills for maintaining them.
Follow that precedent rather than inventing fuzzy matching.

## Steps

### Step 1 — `UexClient`

`app/lib/uex/client.rb` (`app/lib` is where every other external-data loader
lives — `rsi/`, `sc_data/`, `patreon/`; `app/services` holds one unrelated
class). Four GETs, `User-Agent` set, JSON parsed, non-`ok` `status` raised. Base
URL from `Rails.configuration.uex.endpoint` (`config/app/uex.yml`, overridable
via `UEX_ENDPOINT`), matching how `config/app/rsi.yml` is wired, so it can be
pointed at a fixture host in tests. No token handling — add it only if we later
need a write or user endpoint.

### Step 2 — `Uex::VehicleMatcher`

Wraps the layered lookup from decision 3. `MAPPINGS` runs *first*, as an
override, then slug → name → name_full: the hand-curated entry should win over a
generic match so a wrong name collision can always be corrected. Returns `nil` on
a miss and collects misses so the job can report them. Unit-tested against a
fixture, including one case per layer.

`MAPPINGS` keys on the UEX slug and points at our `Model` slug (not name) —
`slug` is the matcher's primary key everywhere else, and it avoids repeating
`San'tok.yāi`'s apostrophe and macron.

### Step 3 — `Uex::PriceSyncer`

- Build a terminal lookup, keeping only `type` in `vehicle_buy` / `vehicle_rent`.
- `location` ← terminal `name`. It is already the right string:
  `"Astro Armada - Area 18"`, `"New Deal - Teasa Spaceport - Lorville"`,
  `"Buy and Fly - Ruin Station"`. No need to compose it from the city/planet
  parts, and it matches the old `shop.name + location_label` shape.
- `location_url` ← `contact_url` when present (it is null for every vehicle
  terminal today, so expect nil).
- Upsert per `(item, price_type, location, time_range)` rather than blind
  `create!`, so a re-run updates prices instead of duplicating rows.
- Delete our rows for a model that UEX no longer lists, so ships removed from a
  shop stop showing a stale location. Scope the delete to `Model` item types so
  hand-entered admin rows for other item types are untouched.
- Guard that delete against a bad snapshot, in three layers. An empty feed still
  arrives as HTTP 200 with `status: "ok"`, and reading it as truth would wipe
  every price we hold.
  1. Reject a non-array `data` in the client rather than coercing it — a null
     `data` is malformed, not an empty snapshot.
  2. Treat an empty feed, or one with no vehicle terminal left after filtering,
     as an error.
  3. **Scope deletions per terminal.** A terminal that priced anything in this
     snapshot is authoritative for its own inventory, so one of our rows it did
     not list really is gone. A terminal that priced *nothing* is ambiguous —
     either every ship left or the feed came back short — and only the terminals
     feed settles it: gone from there too, the rows go; still listed, they stay
     and get reported. A flat percentage cannot make this call, because a real
     terminal is a small share of the total (Astro Armada is 10.9% of rows, so
     any threshold loose enough to permit real churn also permits losing it).
     `MAX_REMOVAL_RATIO` stays as a backstop for the one case the rule cannot
     judge: terminals that report, but report short.

  Upserts still apply throughout; only the destructive half is held back, and
  anything preserved is reported to AppSignal with the locations named.
- Wrap in a transaction and report counts: created / updated / removed /
  unmatched.

### Step 4 — `Loaders::UexPricesJob` + schedule

Sidekiq job on the `loaders` queue, following `Loaders::ModelsJob`. Add to
`config/sidekiq_schedule.yml`:

```yaml
loaders_uex_prices_job:
  cron: '0 5 */1 * *' # Daily at 5:00
  class: 'Loaders::UexPricesJob'
  queue: 'loaders'
  enabled: <%= Rails.env.production? %>
```

05:00 UTC keeps it clear of the existing daily band (metrics 01:00, cleanups
02:00/03:00, Patreon 04:17) and well away from the 19:00–22:00 loader block.

### Step 5 — Report unmatched vehicles

The other importers open a GitHub issue on mismatch (`7960c3bf8` replaced admin
emails with issue creation for the paints/loaner flows). Do the same here so the
eight-ship mapping stays maintained as UEX adds vehicles, instead of silently
dropping prices.

Two constraints that fall out of `GithubIssueCreator`: it dedupes on a SHA of the
body, so the body must carry **only** the unmatched list — putting the daily
created/updated/removed counts in it would change the digest every run and open a
fresh issue every day. And the creator only runs when there is something
unmatched. The counts go on `import.output` instead, where the admin imports view
already shows them.

### Step 6 — Verify

- Model spec for `sell` vs `buy` mapping (decision 1).
- Syncer spec over a trimmed fixture: create, update, remove-stale, unmatched.
- Manual: run the job locally, then check the ship page's Availability modal on
  a ship with both a buy and a rental row (Avenger Titan and Constellation
  Andromeda both have both).

## Outcome

Ran `Uex::PriceSyncer` against the live API on 2026-08-11 in development:

```
created=632 updated=0 removed=0 unmatched=0
288 sell, 344 rental, 0 buy — 179 models with availability
```

A second run reported `created=0 updated=0 removed=0`, so the upsert is
idempotent. All eight `MAPPINGS` entries resolve. `GET /v1/models/aegs-avenger-titan`
returns an empty `boughtAt`, two `soldAt` locations and three `rentalAt` rows at
`timeRange: "1-day"` — decision 1 lands the right way round.

Also needed, not in the original plan: `Imports::UexPricesImport` has to be added
to `ImportTypeEnum` (then `./bin/generate-schema`) and needs a jbuilder partial at
`app/views/api/v1/imports/uex_prices_imports/`, or `ImportTest`'s
"every broadcasting import type renders its jbuilder partial" fails.

## Notes

- The frontend needs no changes to *work*. `_base.jbuilder` already serialises
  `availability.{boughtAt,soldAt,rentalAt}` and the models controller already
  preloads `:item_prices` on every endpoint that renders a model, so no N+1
  appears now that the table is non-empty.
- Correction to the earlier claim: `Models/BaseMetrics` renders only
  `modelPrice.location` for both `soldAt` and `rentalAt` — not price, not rental
  period. The data is in the payload; showing it is a separate UI change.
- The ship page cannot be checked in a fresh worktree: it has no `.env`, so
  `FRONTEND_ENDPOINT` is unset, the CORS origin list does not include
  `fleetyards.test:8270`, and the model fetch dies after its preflight leaving the
  page body empty. Verified the attribution with a Vitest mount instead.
- Attribution: UEX's API terms (section 5 of <https://uexcorp.space/about/terms>)
  impose no credit requirement, but a "Powered by UEX" link to
  <https://uexcorp.space> now sits under the availability lists in
  `Models/BaseMetrics` as a courtesy. It renders only when the ship has
  availability, since availability on other item types is not UEX-sourced. Text
  rather than their badge image — the CSP `img-src` list would need widening for a
  remote asset.
- Rental period confirmed in-game (see decision 2): 27,165 for the Avenger Titan
  is the 1-day rate. Nothing left open here.
- Buy figures match the in-game board, with one 4 aUEC drift: UEX reports
  1,290,370 at New Deal Lorville against 1,290,366 in game. Expected for a
  community-maintained feed with per-row verification dates, not a sync fault.
- `Model#sold_at` / `#rental_at` already `sort_by(&:price)` and
  `uniq(&:location)`, so duplicate locations across terminals collapse in the
  API response regardless of what we store.
