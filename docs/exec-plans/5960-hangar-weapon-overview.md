# Hangar weapon overview: show and filter hardpoints and firepower across all ships

Working plan for #5960. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The hangar table can show, sort and filter every ship by largest weapon size, alpha and DPS, for the fitted loadout or the stock one.

## Open questions
- None yet.

## What changed

### Phase 1 — Weapon size facts and filter
1. `LoadoutWeapons` (`app/lib/loadout_weapons.rb`) walks a `LoadoutSlots` fitting and counts the fitted `WeaponGun` components by size. It reads the gun rather than the port, recurses through mounts and turrets, and leaves out mining lasers (`type_data.mining`).
2. `loadout_stats` table (`LoadoutStat`): one row per fitting (`Model` stock or `VehicleLoadout`) and environment, holding `max_weapon_size`, `weapon_sizes` and the version it was computed against.
3. Refreshed when a fleetyards loadout is saved (`LoadoutStatsJob` per loadout, every available source) and after every finished sc_data load (`AllJob` enqueues a full refresh). `Maintenance::RefreshLoadoutStatsTask` backfills.
4. `Vehicle.fitted_max_weapon_size_sql` plus the `max_weapon_size` / `public_max_weapon_size` ransackers: active loadout if it has stats, else stock, no guns = 0. `fitted_cargo_filters/sorts` became `fitted_filters/sorts` covering both columns.
5. `maxWeaponSize` / `weaponSizes` in the vehicle and public vehicle payloads (cache keys bumped, preloads via `Vehicle::LOADOUT_PRELOADS`). `maxWeaponSizeGteq/Lteq` in `HangarQuery`, and `maxWeaponSize asc|desc` sorts.
6. Hangar table column and sort `maxWeaponSize` ("Weapons", `2×S3 · 4×S2`) and a "Weapons" filter group, in all 7 locales.

### Phase 2 — Firepower at minimum and maximum weapon power
1. `FittingTree` builds the tree the browser computes from. Stock is the hardpoints endpoint's tree (ship copies, `facts.category`). A loadout is that tree with every fittable hull slot rebuilt from `LoadoutSlots`, using `graft`'s category rule (`useComponentFitting.ts`). `LoadoutWeapons` reads the same tree.
2. `LoadoutFirepower` ports `tallyWeapons`, `dutyCycle`/`capacitor`, the power-port collection and `computeWeaponMaxRatio`. Max ratio is `weaponMaxRatio`, min is one pip over the weapons' draw (with the buff's power ratio), capped by max.
3. On the client, `computeLoadoutStats`' loop became `tallyWeapons`. `computeFirepower` runs it at both ratios, and the sim exposes `weaponDraw`.
4. Shared fixtures in `test/fixtures/loadout_stats/*.json`: ten real ships' API trees, pruned to power and ordnance nodes, with the expected figures. `useLoadoutStats.fixtures.spec.ts` and `test/models/loadout_firepower_test.rb` both read them. `UPDATE_LOADOUT_STATS_FIXTURES=1` rewrites them from the TypeScript side.
5. `loadout_stats` gains `alpha`, `burst_dps`, `sustained_dps_min`, `sustained_dps_max` and `formula_version` (`LoadoutFirepower::VERSION`). `RefreshLoadoutStatsTask` recalculates everything.
6. `Vehicle.fitted_stat_sql(column)` with ransackers for `max_weapon_size`, `alpha`, `burst_dps`, `sustained_dps_max`, plus their `public_` twins. `alphaGteq/Lteq` and `burstDpsGteq/Lteq` filters, and sorts on alpha, burst and sustained (max).
7. Payload fields `alpha`, `burstDps`, `sustainedDpsMin`, `sustainedDpsMax`. Table columns Alpha, Burst DPS, and Sustained DPS (shown as min–max). Alpha/DPS range inputs in the Weapons filter group. All 7 locales.

## Intent Verification

- [ ] **Size filter**: a hangar filtered to "≥ S3" lists only ships with an S3+ weapon slot, and a ship whose active loadout drops its S3 gun no longer appears
- [ ] **Stock fallback**: a vehicle without a loadout shows its model's stock figures
- [ ] **Parity**: the vitest and minitest runs of every fixture produce identical stats
- [ ] **Power range**: an energy-weapon ship that is short on power shows a lower min than max sustained DPS, and a ballistic-only ship shows min == max
- [ ] **Table**: the weapon columns can be enabled in Display Options and sort correctly
- [ ] **Recalc**: after a stats version bump, the maintenance task rewrites stale rows

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/composables/useLoadoutStats.ts` | Client calculation (alpha/DPS) |
| `app/frontend/frontend/composables/useLoadoutSim.ts`, `powerSim.ts` | Power simulation the calculation depends on |
| `app/models/hardpoint.rb` | Categories, nesting, `facts` / `in_build` |
| `app/models/vehicle.rb` | `fitted_cargo_sql` precedent, ransackers |
| `app/models/vehicle_loadout.rb` | `after_save :write_item_list`; hook for stored stats |
| `app/lib/sc_data/loader/models_loader.rb` | Writes model build facts |
| `app/lib/sc_data/parser/items_parser.rb` | Weapon `type_data` (damage_per_shot, fire_rate, pellets) |
| `app/api_components/v1/schemas/queries/hangar_query.rb` | Hangar filter params |
| `app/frontend/frontend/stores/hangar.ts` | Table column and sort enums |
| `app/frontend/frontend/components/Hangar/FilterForm/index.vue` | Filter UI |

## Not in scope (deferred)
- **Firepower chart on hangar stats**: nice to have. Becomes its own issue before the PR merges.
- **Fleet-level weapon overview**: same data, different page.

## Discovery Log

- **2026-10-24** Initial research and plan creation. Found that DPS and alpha depend on the power simulation (~1,700 more lines), so the port is far larger than `useLoadoutStats.ts` alone.
- **2026-10-24** Decided on min/max weapon power instead of the full allocator (see the issue). The port drops to the stats functions, port construction and `computeWeaponMaxRatio`.

- **2026-10-25** A source is per request (live/ptu), so stats are stored per environment, not per model build. A loadout keeps the stock parts it leaves in, so loadouts are recalculated after every load as well as on save. The refresh has to run after `import.finish!`: until then `Source#served` still answers with the previous build.
- **2026-10-25** Fleet vehicle lists render the new fields too (shared public partial), but `FleetVehicleQuery` has no weapon filter yet.

- **2026-10-25** The stock tree matches the rendered hardpoints endpoint on all 215 in-game dev-DB ships, firepower and sizes both. A loadout with no changes differs from stock only on the MDC, where `LoadoutSlots` holds a gun the ship copy does not (the loadout page shows the same).
- **2026-10-25** Stock figures do not graft the modules a ship takes, because the ship page does not either. This reverses the review fix that counted them: one figure per ship.

## Progress
- [x] Phase 1
- [x] Phase 2
