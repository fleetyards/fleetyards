# UEX Commodity Trade Data

**Date:** 2026-09-27 (measured against the live UEX API 2026-09-26)
**Status:** Reference

What UEX's commodity terminals, prices and routes actually contain, and the traps in them that shaped the trade routes tool. Read it before changing `Uex::TerminalSyncer`, `Uex::CommodityPriceSyncer`, `Uex::TradeRouteSyncer` or `TradeRoutes::Ranking`.

## Terms and limits

- The API allows 120 requests a minute and 172,800 a day. It needs no token, but answers 403 without a `User-Agent`.
- UEX's terms of use (`/about/terms`) carry no attribution requirement. We credit them anyway, with a "Prices powered by UEX" link next to the prices.
- `commodities_routes` only answers per commodity (`id_commodity`) or per origin terminal. There is no wholesale variant, so a full refresh is one call per mapped commodity: 185 on 2026-09-26, about 4,400 calls a day at an hourly refresh.

## Terminals

- `/terminals/` lists 826 terminals, 161 of type `commodity`. Only those appear in `commodities_prices_all` and `commodities_routes`. `commodity_raw` (refinery ore sales) never does.
- On 2026-09-26 no two live commodity terminals share a name. Same-name terminals are still possible, which is why prices are keyed on the terminal rather than the name.
- `max_container_size` is 0 for 56 of the 161. That means nobody has measured it, not that the terminal takes no crates.
- Availability: `is_available_live` is the flag that tracks the game. Several terminals are listed while unavailable.

## Prices

UEX writes from the player's side, so `price_buy` is what a player pays and `price_sell` is what they receive. The stock follows the direction:

| UEX field                       | Means                                 | Where it goes          |
| ------------------------------- | ------------------------------------- | ---------------------- |
| `price_buy` / `scu_buy`         | price and stock a player can buy      | shop `sell` row, `scu` |
| `price_sell` / `scu_sell_stock` | price and demand a terminal will take | shop `buy` row, `scu`  |
| `date_modified`                 | when a contributor last reported it   | `source_updated_at`    |

`scu_buy` matches the route's `scu_origin` (211 = 211 for Agricium at SMCa-8). `scu_sell` is usually 0 and is not the demand.

## Routes

- A route row has no `date_modified`. Each end's price age has to be read from `commodities_prices_all`, which costs one extra call per refresh.
- `container_sizes_origin` / `_destination` are comma-separated strings. The crate sizes a run can actually use are origin ∩ destination ∩ the commodity's own sizes. A few commodities only ship in 0.01 SCU boxes, so nothing fits a freight crate and those routes are dropped (24 on 2026-09-26).
- Negative margins occur; the worst Agricium route was −24.7%. Of 8,997 routes, 1,238 lose money or have nothing to carry.
- About half of all routes cross a system boundary. On 2026-09-26, 5,150 start in Stanton, 2,253 in Pyro and 332 in Nyx.
- Gateway-to-gateway routes report a distance of 0. Profit per distance must not divide by it.
- Admin terminals at the gateways report a placeholder stock of 250,000 SCU (Waste). Ranking by stock × margin without a ship puts these first. With a ship, its hold caps the load anyway.

## What the live data says about ranking

- **Staleness dominates an unfiltered list.** Ranked for a Freelancer MAX, the top route's prices were 20 days old and the next-best was 3 days old. With a 3-day price age, 1,244 of 7,735 routes remain. That is why the tool defaults to 3 days.
- **One purchase floods the list.** Taranite bought at Samson & Son's filled six of the top eight rows with different destinations. That is why runs are grouped by commodity and buy terminal.
- **The hold is rarely the limit.** Among the top runs for a 120 SCU ship with a 2M budget, most loads were capped by stock (52 SCU of Audio-Visual Equipment) or budget, not by the hold. That is why each run says what limits its load.
- **Stock, demand and budget come in crates.** A 5 SCU stock cannot fill an 8 SCU crate, so these limits round down to whole crates of the smallest allowed size.
