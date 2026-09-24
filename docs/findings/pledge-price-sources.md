# Pledge Price Sources: RSI vs UEX

**Date:** 2026-09-24 (research 2026-08-12)
**Status:** Reference; the `pledge_prices` table was proposed but never built

Where RSI pledge-store prices can come from, how UEX's figures compare to the RSI figures Fleetyards already shows, and why CCU prices have no source. Read this before adding warbond, concierge, package or CCU prices, or before switching the displayed pledge price to another feed.

## Current holders

| Holder                                | Meaning                                 | Written by                                                                                         |
| ------------------------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `models.pledge_price` `decimal(15,2)` | current standalone MSRP, excl. VAT      | `Rsi::PledgeStoreLoader` from GraphQL `msrp / 100.0`, keeping the held value when RSI omits `msrp` |
| `models.rsi_pledge_value` `integer`   | the same figure in cents (a duplicate)  | same loader                                                                                        |
| `models.on_sale` `boolean`            | RSI `purchasable` ("buyable right now") | same loader                                                                                        |
| `model_upgrades.pledge_price`         | upgrade kit prices                      | admin form only                                                                                    |

Nothing holds warbond, concierge or package prices, and nothing keeps a previous price.

## The UEX feed

`GET https://api.uexcorp.uk/2.0/vehicles_prices/` needs no auth, but it does need a `User-Agent` header (without one it returns 403). On 2026-08-12 it returned 786 rows over 260 vehicles. There is one row per `(vehicle, game_version)`, so **the feed is a history, not a snapshot**: 3 rows per vehicle on average, up to 6.

```json
{
  "id": 1,
  "id_vehicle": 107,
  "price": 210,
  "price_warbond": 0,
  "price_package": 0,
  "price_concierge": 0,
  "on_sale": 0,
  "on_sale_warbond": 0,
  "on_sale_package": 0,
  "on_sale_concierge": 0,
  "currency": "USD",
  "game_version": "4.0.2",
  "date_added": 1703566807,
  "date_modified": 1741107787,
  "vehicle_name": "Hurricane"
}
```

| Field             | Rows non-zero | Distinct vehicles |
| ----------------- | ------------: | ----------------: |
| `price`           |     779 (99%) |               255 |
| `price_warbond`   |     147 (19%) |                95 |
| `price_package`   |      76 (10%) |                30 |
| `price_concierge` |       37 (5%) |                29 |

`on_sale = 1` on 476 rows, `on_sale_warbond = 1` on 24. A row's `on_sale` means "this price was a sale price". That is not the same as `models.on_sale` ("buyable right now"), so one must never overwrite the other.

`price_package` is not a package entity. It is what the ship costs when bought inside a package, a per-model figure.

## UEX does not match RSI's standalone price

We took the newest UEX row per vehicle and compared it with our `pledge_price`. 231 models matched:

| Relationship | Models | Reading                                                            |
| ------------ | -----: | ------------------------------------------------------------------ |
| identical    |     76 | agree                                                              |
| UEX ≈ ×1.071 |    ~55 | UEX figure is tax-inclusive (Javelin: ours $3000, UEX $3213)       |
| UEX = ×0.9   |     34 | UEX row is a sale or warbond price (Ironclad: ours $600, UEX $540) |

Our figure is RSI's `msrp`, excl. VAT, which is also how the RSI ship page labels it ("On Sale: $155 excl. VAT"). So **RSI stays the source of the displayed standalone price**. UEX is only useful for the kinds we have no other source for (warbond, concierge, package) and for price history.

Do not store UEX standalone prices at a ~7.1% discount to "fix" them. Nobody knows whether the uplift is VAT, a regional rate, or UEX storing gross prices for some entries. Dividing by a guessed constant would turn that uncertainty into a number that looks exact. A UEX standalone row is still worth keeping, because a warbond price means nothing without the standalone price from the same row. It must not be shown next to the RSI figure: two different prices on one card is the same bug that was fixed for the in-game price.

## CCU prices have no source

- UEX has no CCU or pledge endpoint beyond `vehicles_prices`. `vehicles_pledges`, `vehicles_pledge_prices` and `vehicles_prices_pledges` all return 404, and the API docs list nothing else pledge-related.
- RSI's `TySkuUpgradeFragment` returns id, title, subtitle, slug, isWarbond and stock, but no price. Getting CCU prices would mean scraping RSI's upgrade store, which is a separate project.
- A CCU price belongs to a pair of models (from → to). It fits neither a per-model price table nor `item_prices` without a second model reference.

If a CCU tool is the goal, the first question is where the prices come from, not where they are stored.

## Proposed `pledge_prices` table (not built)

The idea copies the in-game price setup: `pledge_prices` would be the record and `models.pledge_price` the derived cache, just as `item_prices` is for `models.price`.

| Column              | Type                    | Note                                                       |
| ------------------- | ----------------------- | ---------------------------------------------------------- |
| `model_id`          | uuid, not null          |                                                            |
| `kind`              | integer, not null       | enum `standalone: 0, warbond: 1, concierge: 2, package: 3` |
| `price`             | decimal(15,2), not null |                                                            |
| `currency`          | string, default `"USD"` | the feed states it per row                                 |
| `game_version`      | string                  | null for a row with no version                             |
| `on_sale`           | boolean, default false  | per-kind sale flag, not the model-level one                |
| `source`            | integer, not null       | enum `uex: 0, rsi: 1, manual: 2`                           |
| `external_id`       | integer                 | UEX row `id`                                               |
| `source_updated_at` | datetime                | from `date_modified`                                       |

Unique index on `(model_id, kind, game_version, source)`, plus an index on `model_id`.

Why a table and not more columns on `models`:

- The kinds are sparse. Only 30 of 246 models have a package price, so the columns would be mostly null.
- History is the point, and columns cannot hold it.
- A new kind becomes a row, not a migration.

Behaviour worked out for a syncer:

- **Rows are only ever added.** A row missing from the feed means an old patch dropped out of the window, and the price was true at the time. This is the opposite of `Uex::PriceSyncer`, where a missing row means a shop stopped stocking the ship.
- Keep a guard that raises on a 200 response with no data.
- Sync weekly. Store prices change with patches and sales, and the feed is tagged by version rather than live.
- Match vehicles with `Uex::VehicleMatcher`. The feed covers 260 vehicles, against the 179 in the in-game sync, so expect new misses and report them through the existing GitHub-issue path.
- A full run should give roughly 255 standalone, 95 warbond, 30 package and 29 concierge rows.
