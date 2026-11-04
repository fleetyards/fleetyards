# CCU Availability: Which Ships Take Upgrades

**Date:** 2026-11-04 (research 2026-10-30)
**Status:** Reference; built as `Rsi::CcuCatalogue`, `Model#ccu_target_status` and `Model#ccu_source_status`

Which ships RSI sells a CCU into or out of, where Fleetyards learns it, and why simpler rules failed. Read this before changing what the hangar planner offers as a start, an end or an upgrade target, or before adding another CCU source.

## Why the store alone is not enough

The pledge store's GraphQL `GetShip` query returns an `upgrades` list per ship: the CCU SKUs into that ship that are **on sale today**. Measured on 2026-10-30:

| Ship          | `upgrades` |
| ------------- | ---------- |
| Cutlass Black | 1          |
| Cutlass Red   | 0          |
| Cutlass Blue  | 0          |
| Cutlass Steel | 0          |
| Pioneer       | 0          |
| Kraken        | 0          |

The Red, Blue and Steel are standard ships with CCUs in many hangars, but none was on sale that day. Most CCUs come back only for a sale, so the store answers "on sale now", never "exists".

## Sources and how they combine

| Holder                      | Meaning                                       | Written by                                                   |
| --------------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| `models.ccu_target_seen_at` | a CCU into the ship was seen, first date kept | `Rsi::CcuCatalogue` (daily, 20:30), `Rsi::PledgeStoreLoader` |
| `models.ccu_source_seen_at` | a CCU out of the ship was seen                | `Rsi::CcuCatalogue`                                          |
| `models.ccu_on_sale`        | the store sells a CCU into the ship today     | `Rsi::PledgeStoreLoader`                                     |
| `models.ccu_override`       | `allowed`, `none` or null                     | admin model form; a data migration marks eight ships `none`  |

`Rsi::CcuCatalogue` reads every CCU title in any synced hangar (`hangar_pledge_items`, kind `ccu`) and every bought-back upgrade, and matches both ends to models through `Rsi::UpgradeTitles`. In the production dump of 2026-10-30 that was **3386 distinct titles reaching 228 target ships**, against 249 visible models. A date, once set, is never cleared: a CCU that left the store has still existed.

The resolution order, in `Model#ccu_target_status` and the `ccu_target` scope:

1. A ship the store never sells (`ingame_only`, or not `player_ownable`) has none.
2. An override of `none` wins.
3. `on_sale` if the store sells one today.
4. `sales_only` if one was ever seen, or an admin allowed it.
5. `unknown` for a ship listed under 90 days ago that nobody has seen one for yet.
6. `none` otherwise.

A ship seen as a CCU target counts as a source too, since whatever a CCU reaches can be upgraded further. Only store-bought steps are validated against this. A CCU the user holds or can buy back exists whatever the catalogue says.

## Rules that were tried and failed

- **A price cap of $1000.** It let the Pioneer ($925, no CCU ever) through, and blocked real CCUs between expensive ships: "Kraken to Kraken Privateer" and "890 Jump to Polaris" both exist.
- **CCUs from at least N different source ships.** Distinct sources per target in the dump: 17 targets have one, 15 have two. Those include standard cheap ships such as the Mustang Alpha, Aurora MR and Pulse, which few ships are cheaper than. A threshold blocks them.
- **Per-pair evidence.** An Aurora ES can be upgraded into a Mustang Alpha though no hangar shows that pair. RSI sells standard CCUs from any cheaper eligible ship, so per ship is the right grain. The exceptions are one-off pairs, which the override handles: the Kraken Privateer's only CCU starts on the Kraken.

## RSI's upgrade tool

`POST https://robertsspaceindustries.com/pledge-store/api/upgrade/graphql` answers `initShipUpgrade { ships { id name msrp } }` without a login: 242 ships on 2026-10-30, the Kraken absent, the Pioneer present. Which targets a ship reaches (`to(from:)`) needs a signed-in account (`Cannot read properties of null (reading 'account')`). The reverse lookup without one answers "Ship not found". So the tool cannot be imported server side, and its ship list alone does not separate the Pioneer from ships with CCUs.

## Ships marked by hand

The data migration `MarkShipsWithoutCcus` sets `none` on the Idris-P, Idris-M, Javelin, Kraken, Kraken Privateer, Odin, 890 Jump and Pioneer, unless an admin already chose. Seven of them had no evidence anyway. The marking keeps a stray CCU title from ever reopening them.
