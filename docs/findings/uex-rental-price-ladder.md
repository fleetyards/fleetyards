# UEX Rental Price Ladder

**Date:** 2026-09-24 (research 2026-08-11)
**Status:** Reference; confirmed against one ship only

UEX publishes only one rental price per ship, and this note says which duration it is and how to work out the other three. Read it before showing rental durations or adding another rental source.

## UEX `price_rent` is the 1-day price

`/vehicles_rentals_prices_all/` has exactly one row per `(vehicle, terminal)`: 344 rows, 344 distinct pairs, and no duration field. Rent as a share of the purchase price sits tightly around 2.5% (M50, 300i and 600i Explorer are all exactly 2.50%). That points to a single fixed duration.

On 2026-08-11 an in-game rental board for the Avenger Titan, which prices all four durations, confirmed it: UEX's 27,165 is the 1-day price.

## Longer rentals come from the 1-day price

For each longer period the per-day rate drops by an eighth. This reproduces all three in-game figures exactly:

| Period  | Per-day rate | Total multiplier | Predicted | In game |
| ------- | -----------: | ---------------: | --------: | ------: |
| 1 day   |            1 |               1× |    27,165 |  27,165 |
| 3 days  |          7/8 |           2.625× |    71,308 |  71,308 |
| 7 days  |          3/4 |            5.25× |   142,616 | 142,616 |
| 30 days |          5/8 |           18.75× |   509,344 | 509,344 |

So longer rentals are discounted, not linear. Taking the UEX figure as a 30-day price would have been wrong by 18.75×.

## Why only the 1-day row is stored

Only the 1-day row goes into `item_prices` (`time_range: "1-day"`). Storing the other three adds no information and quadruples the rental rows. `item_prices` also cannot mark a row as derived rather than sourced, so derived rows would look as trustworthy as the published ones, and a change to the ladder would go unnoticed. If a UI needs the other durations, calculate them at render time from the 1-day row. The `time_range` enum already lists all four durations, so a source that publishes them can store them without a migration.
