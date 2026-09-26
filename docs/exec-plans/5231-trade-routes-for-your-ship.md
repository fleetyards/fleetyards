# Trade routes: profitable commodity runs for the ship you fly

Working plan for #5231. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`/trade-routes/` ranks single-leg commodity runs between two UEX terminals by profit for a chosen ship, from UEX data we sync ourselves.

## Open questions
- None. Path, route source, the `ItemPrice` terminal link, the hourly refresh and the feature flag are decided in the issue body.

Resolved by research: UEX's terms (https://uexcorp.space/about/terms) do not require attribution. We still credit them with the existing `model.poweredByUex` link, as `AvailabilityModal` already does.

## What changed

### Phase 1 — Terminals
1. `Uex::Client#get` takes query params; add `commodities_routes(id_commodity:)`. `terminals` already exists.
2. `Terminal` model + migration: `uex_id` (unique), name, nickname, star system, planet, moon, orbit, space station / city / outpost names, `max_container_size`, freight elevator / loading dock / docking port flags, availability, `contact_url`.
3. `Uex::TerminalSyncer`: upserts `type == "commodity"` terminals and marks the missing ones unavailable instead of deleting them.
4. Extend `test/fixtures/uex/terminals.json` with geo and flag fields.

### Phase 2 — Prices on terminals
1. Migration: `item_prices.terminal_id` (nullable FK, nullify on delete; non-commodity prices have no terminal), `scu` and `source_updated_at` (UEX `date_modified`). `item_price_snapshots.terminal_id`, which joins the unique day index (still `NULLS NOT DISTINCT`).
2. `CommodityPriceSyncer` runs `Uex::TerminalSyncer` first and keys prices by terminal, so same-name terminals no longer collapse. `location` stays the terminal name for display. Stock follows direction: `scu_buy` on a shop-sell row, `scu_sell_stock` on a shop-buy row.
3. `PriceSnapshot`: `price_key` adds the terminal as a fifth part (nil for vehicle/component/equipment syncers, so they are unchanged). A name-only row is adopted by its terminal on the first run instead of replaced. Retention and `live` count per terminal where known.
4. Import output and the notification carry the terminal counts.
5. Vehicle, component and equipment prices stay name-only: `Terminal` holds commodity terminals only.
6. API exposure of terminal/stock/freshness on `ItemPrice` moves to phase 4, together with the `Terminal` component.

### Phase 3 — Trade routes sync
1. `TradeRoute`: commodity, origin/destination terminal, both prices, `scu_origin`/`scu_destination`, container sizes at both ends (integer arrays), distance, and the price timestamp at each end. Unique on commodity + both terminals. Profit per SCU is computed, not stored.
2. `Uex::TradeRouteSyncer`: one `commodities_routes` call per commodity with a `uex_id`, one second apart. Routes that lose money, have no reachable SCU, or touch a terminal we don't hold are dropped. Each commodity's set is replaced in its own transaction. A failed call keeps that commodity's previous routes, and the sync raises only if every call fails. Routes of commodities that lost their mapping are removed.
3. Freshness: routes carry no `date_modified`, so each run makes one `commodities_prices_all` call and reads each end's timestamp from it.
4. `Loaders::UexTradeRoutesJob`, hourly at :10: `TerminalSyncer`, then `TradeRouteSyncer`. A clean run only logs, with no `Import` record and no notification. Failed commodities raise one `uex_trade_routes_sync` warning (no GitHub issue), whose body lists only the failed commodities, so a repeating failure updates one unread row.
5. The notification type is registered in the enum and `TYPES`, with labels in 7 locales, the admin swagger and the cable asyncapi.

### Phase 4 — API
1. Integration test first: `GET /api/v1/trade-routes` with filters (system, commodity, origin, destination) and `model` slug (+ optional module slugs).
2. Ship fit: loadable SCU = sum over the ship's `CargoHoldContainerCapacity` rows whose container size is ≤ both terminals' max and allowed for the commodity (`container_sizes`), capped by `scu_origin` and `scu_destination`. Profit per run = loadable SCU × margin; also profit per distance and investment.
3. Sort by profit, profit per distance, margin, ROI; pagination.
4. Components: `TradeRoute`, `TradeRouteList`/paginated, `Terminal`, query component, sort enum. Facet endpoints for systems and terminals if the filters need them.

### Phase 5 — Frontend
1. `/tools/trade-routes/`: page, route in `pages/tools/routes.ts`, route-name union, ToolsNav item, tools landing card, SSR meta in `config/routes/frontend_routes.rb`. `/trade-routes/` redirects there server-side and in the router.
2. Ship picker: wrap `Models/PickerModal` like `CargoGrids/Models/PickerModal` (hangar-only toggle when signed in).
3. Mobile-first route rows: commodity, origin → destination with location, loadable SCU, profit, investment, distance, price freshness from `date_modified`.
4. Filters for system, commodity, origin, destination. UEX credit.
5. Behind a `trade_routes` flag in `config/feature_flags.yml`, checked through `FeatureFlagName`.
6. Labels in all 7 locales. Reuse or replace the orphaned `labels.tradeRoutes` / `labels.filters.tradeRoutes` keys.

## Intent Verification

- [ ] **Old links work**: `/trade-routes/` redirects to `/tools/trade-routes/` instead of the 404.
- [ ] **Ship-aware**: choosing a ship changes loadable SCU and profit. A ship whose holds only take small containers loses routes where a terminal only accepts large containers, or earns less on them.
- [ ] **Stock caps**: loadable SCU never exceeds origin stock or destination demand.
- [ ] **Separate terminals**: two UEX terminals with the same name appear as two terminals.
- [ ] **Freshness**: each row shows how old its prices are.
- [ ] **Sync health**: the job reports counts, drops non-profitable routes, and a failing commodity call leaves that commodity's previous routes in place.
- [ ] **Hangar**: signed-in readers can restrict the picker to ships they own.
- [ ] **Mobile**: usable at 375px width without horizontal scroll.
- [ ] **Attribution**: UEX is credited on the page.

## Key files

| File | Role |
|------|------|
| `app/lib/uex/client.rb` | UEX HTTP client; needs query params |
| `app/lib/uex/commodity_price_syncer.rb` | Existing commodity price sync; merges terminals by name |
| `app/lib/uex/price_snapshot.rb` | Price persistence/retention; match key moves to terminal |
| `app/lib/uex/commodity_matcher.rb` | `DUPLICATES` mapping |
| `app/jobs/loaders/uex_commodity_prices_job.rb` | Job/import/report pattern to copy |
| `config/sidekiq_schedule.yml` | Schedule |
| `app/models/cargo_hold.rb`, `cargo_hold_container_capacity.rb` | Container fit data |
| `app/models/commodity.rb` | `uex_id`, `container_sizes` via `CommodityBuild` |
| `app/frontend/frontend/pages/tools/routes.ts` | Tool routes |
| `app/frontend/frontend/components/CargoGrids/Models/PickerModal/index.vue` | Picker wrapper to copy |
| `app/frontend/frontend/components/AvailabilityModal/index.vue` | Existing UEX credit |
| `test/support/uex_fixtures.rb`, `test/fixtures/uex/` | UEX client stubs and fixtures |

## Not in scope (deferred)
- **Multi-leg routes and loops**: out of scope per the issue.
- **Route → fleet hauling contract**: natural follow-up with fleet contracts/inventories.

## Discovery Log

- **2026-09-26** Initial research and plan creation. No Terminal/Station models survive: `20250304083059_cleanup_stations.rb` dropped them along with the old `trade_routes` table. `Uex::Client` has no auth and no rate limiting. The UEX terms have no attribution clause, and the rate limit is 120/min.

- **2026-09-26** Live UEX: 826 terminals, 161 of type `commodity`. Only those appear in `commodities_prices_all` (2,602 rows) and `commodities_routes`; `commodity_raw` (refinery ore sales) never does. There are no duplicate names among live commodity terminals today, so the same-name merge is latent, not active. `max_container_size` is 0 (unknown) for 56 of them. Price rows carry `scu_buy`, `scu_sell_stock`, `status_buy/sell`, `container_sizes` and `date_modified`. Route rows carry container sizes as comma-separated strings, and negative margins do occur (min −24.7 for Agricium).

- **2026-09-26** Phase 2 dry run on production commodity data (2,595 prices, copied into the worktree DB) against the live feeds, in a rolled-back transaction: 161 terminals created, all 2,595 rows adopted with their ids kept, 6 created, 0 removed. 2,601 linked, 2,260 with stock.

- **2026-09-26** Phase 3 dry run on live UEX (185 mapped commodities, not ~114; ~4,400 calls a day hourly) against the worktree DB, rolled back: 0 failed, 7,759 routes kept, 1,238 dropped as unprofitable, 0 with an unknown terminal. All have both timestamps and a distance. By origin: Stanton 5,151, Pyro 2,276, Nyx 332; about half cross a system boundary, so the system filter must say whether it matches origin, destination or both. Two traps for phase 4: admin terminals report placeholder stock of 250,000 SCU (Waste at the gateways), so stock-times-profit without a ship ranks nonsense first; and gateway pairs have distance 0, so profit per distance needs a guard.

## Progress
- [x] Phase 1 — Terminals (model, syncer, client params; not yet scheduled, it runs from the price job in phase 2)
- [x] Phase 2 — Prices on terminals (API exposure deferred to phase 4)
- [x] Phase 3 — Trade routes sync
- [ ] Phase 4 — API
- [ ] Phase 5 — Frontend
