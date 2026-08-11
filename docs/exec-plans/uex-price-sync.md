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
the 1-day rate sits in that band. **Recommendation: store `1-day`.** It should
be confirmed against an in-game terminal before shipping — if it turns out to be
30-day, every rental figure is wrong by ~30×, and nothing in the data would tell
us. The alternative is relaxing the validation to allow a null `time_range`,
which is honest but pushes an "unknown period" case into the UI.

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

`app/services/uex/client.rb`. Three GETs, `User-Agent` set, JSON parsed, non-`ok`
`status` raised. Base URL from `ENV.fetch("UEX_API_URL", "https://api.uexcorp.uk/2.0")`
so it can be pointed at a fixture host in tests. No token handling — add it only
if we later need a write or user endpoint.

### Step 2 — `Uex::VehicleMatcher`

Wraps the layered lookup from decision 3: slug → name → name_full → explicit
`MAPPINGS` hash for the eight. Returns `nil` on a miss and collects misses so the
job can report them. Unit-tested against a fixture, including one case per layer.

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

### Step 6 — Verify

- Model spec for `sell` vs `buy` mapping (decision 1).
- Syncer spec over a trimmed fixture: create, update, remove-stale, unmatched.
- Manual: run the job locally, then check the ship page's Availability modal on
  a ship with both a buy and a rental row (Avenger Titan and Constellation
  Andromeda both have both).

## Notes

- The frontend needs no changes. `_base.jbuilder` already serialises
  `availability.{boughtAt,soldAt,rentalAt}`, and the Base card's Availability
  modal already renders location, price and rental period.
- Attribution: UEX data is community-maintained. Check their terms for a
  required credit before shipping, and if one is needed put it in the modal
  footer.
- `Model#sold_at` / `#rental_at` already `sort_by(&:price)` and
  `uniq(&:location)`, so duplicate locations across terminals collapse in the
  API response regardless of what we store.
