# Cart Trip Planning: Where a Price Is, and What "Distance" Can Mean

**Date:** 2026-10-26 (measured against the production dump of that week; tracked in #6001)

The shopping cart plans where to buy each line: the cheapest place, the fewest stops, or the shortest trip. This note records what the price data says about places, why the shortest trip counts hops rather than kilometres, and what a real distance would need. Read it before changing `Carts::TripPlan` or adding anything that routes between shops.

## Where a price is

`item_prices` names its place three ways, and the cart needs all three:

| catalogue | `sell` rows | with a shop | without a shop |
| --------- | ----------: | ----------: | -------------: |
| Component |       4,465 |       4,465 |              0 |
| Equipment |      19,291 |      18,952 |            339 |
| Commodity |         704 |           0 | 704 (terminal) |

Gear is priced per shop, commodities only per terminal, and a few hundred gear prices name a place UEX gave us that matched neither. So a price's place is the shop's location, else the terminal's location, else the raw UEX name. Two shops at one station are one stop: a stop is where you fly to, and each line still names its shop.

The UEX price sync updates `item_prices` rows in place and only deletes rows UEX no longer lists. A cart line pinned by `item_price_id` therefore survives syncs; when its row is deleted the pin is nulled and the line falls back to its plan's place.

## Why distance counts hops

Locations carry no coordinates, only the parent/system tree (`parent_id`, `system_id`, `kind`). The one source of real distances is `trade_routes.distance`, which UEX reports per terminal pair: 7,318 rows. It does not cover the cart's case:

- Gear shops are not terminals, so most stops have no pair at all.
- Even among terminals, a pair only exists where a commodity trades between them.

The shortest-trip plan instead weighs hops in the location tree, using `Carts::TripPlan::HOP_COST`:

- another place on the same planet or moon costs 1
- another planet or moon costs 3
- another system costs 10

A place's planet or moon is the first of the location, its parent and its grandparent whose `kind` is `planet` or `moon`. A place on neither, such as a Lagrange station, is a body of its own.

On a sample seven-line list, the three plans came out as follows:

| plan          | stops | systems | total (aUEC) |
| ------------- | ----: | ------: | -----------: |
| cheapest      |     6 |       2 |      123,458 |
| fewest stops  |     4 |       2 |      126,027 |
| shortest trip |     5 |       1 |      130,066 |

## What a real distance would need

Positions per location, or at least per planet, moon and station, in the same frame per system. The game files do carry object containers with positions. Nothing in the current parse exports them, so that is a parser change before it is a planner one. With positions, the greedy set cover in `TripPlan#shorten_trip` can keep its shape and swap `trip_cost` for a route length.
