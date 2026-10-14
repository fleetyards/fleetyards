# Hide specific synced ships from the hangar

Working plan for #5674. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A user can hide a ship (and with it its loaners and bundled snub crafts) from everything that counts their hangar, keep it matched by the hangar sync, and bring it back through a hangar filter.

## What changed

### Phase 1 — Model

1. Migration: `vehicles.hidden_by_user boolean, default false, null false`.
2. `Vehicle.visible` becomes `hidden: false, hidden_by_user: false`, so every existing consumer (hangar, stats, public hangar, fleets, wishlist, metrics, discord) drops a hidden ship without being touched.
3. Loaners and bundled snub crafts copy `hidden_by_user` from their parent, the same way they copy `wanted`.
4. The loaner dedup group (one row with `hidden: false` per group) is keyed on `(model, wanted, hidden_by_user)` instead of `(model, wanted)`: `create_loaner`, `reveal_loaner_groups`, `revisit_loaner_visibility`, `out_of_sync_loaner_parent_ids`, `RepairLoanerFlagsTask`. Otherwise hiding the parent of a group's single visible loaner leaves the group with none.
5. Moving a ship to the wishlist clears `hidden_by_user` (the filter lives on the hangar only).
6. Fleet side: `FleetMembership#update_fleet_vehicle` drops the `FleetVehicle` of a vehicle hidden by its owner. The existing `after_commit` already queues the job, since `hidden` stays false on a hidden parent.
7. `Vehicle.public` also excludes `hidden_by_user`: the public hangar, its stats, embeds, OG pages and the Discord `/hangar` command read `.public`, not `.visible`.
8. `check_serial` still sees a hidden ship's serial (the unique index does).

### Phase 2 — API

1. `hidden_by_user` permitted on `update` and `update_bulk`; ignored on loaners/bundled rows (derived).
2. Vehicle payload exposes `hiddenByUser`; `VehicleUpdateInput`, `VehicleUpdateBulkInput`, `Vehicle` components updated.
3. `HangarQuery.hiddenByUserEq` (`true` show / `only`), handled in `HangarFiltersConcern` like `loanerEq`; `ransackable_attributes` untouched since the concern consumes it.
4. The vehicle fragment cache key is bumped, so cached payloads without `hiddenByUser` are not served.
5. Integration tests: hide/unhide, list filter, stats exclusion, public hangar exclusion, sync still matches a hidden ship.

### Phase 3 — Frontend

1. Context menu: hide / unhide action (editable, not wishlist, not loaner/bundled).
2. Bulk list action: hide / show selected.
3. Hangar filter: "Hidden ships" radio (hide default / show / only).
4. A hidden ship shows a ghost marker (panel label, table state) when listed via the filter.
5. Locales in all 7 languages.

## Intent Verification

- [ ] Hiding a synced ship removes it from the hangar list, stats, public hangar and fleets
- [ ] Its loaners and snub crafts disappear with it; another parent's loaner of the same model stays visible
- [ ] A sync after hiding creates no duplicate and leaves the ship hidden
- [ ] The filter lists hidden ships and unhiding brings them back

## Key files

| File                                                              | Role                                                    |
| ----------------------------------------------------------------- | ------------------------------------------------------- |
| `app/models/vehicle.rb`                                           | `visible` scope, loaner/snub derivation, fleet callback |
| `app/models/fleet_membership.rb`                                  | fleet vehicle add/remove                                |
| `app/lib/hangar_sync.rb`                                          | sync matching (must keep matching hidden ships)         |
| `app/tasks/maintenance/repair_loaner_flags_task.rb`               | loaner group key                                        |
| `app/controllers/api/v1/vehicles_controller.rb`                   | update / update_bulk params                             |
| `app/controllers/concerns/hangar_filters_concern.rb`              | `hiddenByUserEq` filter                                 |
| `app/frontend/frontend/components/Vehicles/ContextMenu/index.vue` | hide action                                             |
| `app/frontend/frontend/components/Vehicles/Table/ListActions.vue` | bulk hide                                               |
| `app/frontend/frontend/components/Hangar/FilterForm/index.vue`    | filter                                                  |

## Discovery Log

- **2026-10-14** `vehicles.hidden` is loaner dedup state; sync matches `hidden: false` only. Every hangar consumer already goes through `Vehicle.visible`, so widening that scope covers them.
- **2026-10-14** The public hangar and its stats never used `visible`; they read `Vehicle.public`, so that scope carries the exclusion too.
- **2026-10-14** The migration was never run against a dev database (auto mode blocks `db:migrate`); `db/schema.rb` was edited by hand and the test DB loaded from it.

## Progress

- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Live check in the browser (needs a running dev server)
