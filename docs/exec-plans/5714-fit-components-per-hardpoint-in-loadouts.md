# Fit components per hardpoint in fleetyards loadouts

Working plan for #5714. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A fleetyards loadout can fit a compatible component into any hardpoint on the hull, on a fitted module or on a fitted turret. The editor, the read view and the ship/loadout pages show the stat changes that come from one server-side diff.

## Open questions

- None yet. Decisions so far: an unfitted slot keeps stock, any compatible component can be fitted (badged), fit by category + size, split into #5770 / #5771 / #5772.

## What changed

### Phase 1 — Fitting model (#5770)
1. Add `Component` to `VehicleLoadoutItem::ITEM_TYPES` (`app/models/vehicle_loadout_item.rb:5`). This regenerates the item-type enum schema. Fix the stale "owned by the vehicle" comment.
2. Add a slot resolver that walks a `slot_path` segment by segment down the `Hardpoint` tree:
   - hull `game_files` hardpoints by `sc_name`
   - then the child hardpoints of the fitted module or component, or of the slot's stock component when nothing is fitted
   - using `HardpointBuild` facts for the build in force
3. Add a `components_fit` check beside `modules_fit` (`app/models/vehicle_loadout.rb:115`). The resolved slot must exist, its category/types must match the component's, and the component's size must lie within `min_size..max_size`. Add error keys in all 7 `activerecord.yml` locales.
4. Add `Component#unfit_everywhere`, mirroring `ModelModule#unfit_everywhere` (`model_module.rb:158`), so removing a component cascades its subtree.
5. Tests:
   - flip "refuses anything but a module for now" (`test/models/vehicle_loadout_fitting_test.rb:72`)
   - cover a size or category mismatch, a nested path under a turret and under a module, and the cascade

### Phase 2 — API (#5770)
1. Add a loadout slots endpoint (or extend `/models/:slug/hardpoints`) that returns the slot path, category, size range and stock component per slot, including slots nested under modules and turrets.
2. Add a compatible-components listing per slot. This may reuse `GET /components` with size/category filters.
3. Resolve fitted items in a separate slot tree for a saved loadout (`GET /vehicles/:vehicle_id/loadouts/:id/slots`) rather than in `vehicle_loadouts/_base.jbuilder`, which is cached and embedded in every vehicle payload; a component in it would go stale on any component edit.

### Phase 3 — Server-side stats + shared diff (#5771)
1. Add a `LoadoutStats` lib that grafts the fitted items onto the model's hardpoint tree and computes cargo, hardpoint counts, shields (reusing `ModelDefenses`), power, cooling, quantum and DPS.
2. Add a diff endpoint (saved vs. proposed fitting, and per-option deltas). Replace the client-side `useFittingDiff.ts`.

### Phase 4 — Editor (#5772)
1. Turn the `systemTabs` / `propulsionWeaponTabs` "coming soon" tabs (`LoadoutModal/index.vue:161-210`) into component slot categories. Extend `VehicleLoadoutTabsEnum`.
2. Add a `useComponentSockets` adapter beside `useModuleSockets.ts` that feeds `Loadout/{SocketBoard,Socket,Picker}`, with Owned/Stock/Not owned badges and deltas.
3. Generalise the form state: replace `fittedModules` with fitted items by slot path, and drop children when a parent changes.
4. Translate the new labels in all locales by hand.

### Phase 5 — Read view + ship/loadout pages (#5772)
1. Add component sections in `LoadoutView/index.vue`.
2. Graft fitted components into `useEquippedHardpoints`. It has to key by `sc_name` paths, not `groupKey || id`. This feeds #5713.

## Intent Verification

- [ ] **Component fits by category and size**: a matching component saves, and a mismatched size or category is rejected with a translated error
- [ ] **Nested slots**: a component under a fitted module or turret saves, and unfitting the parent drops it
- [ ] **Coming-soon tabs are gone**: each category lists its slots with compatible components to pick
- [ ] **Read view and ship/loadout pages show fitted components**
- [ ] **Stats come from the server**: shields, power, DPS and quantum change when a component is swapped, and editor, read view and pages show the same numbers

## Key files

| File | Role |
|------|------|
| `app/models/vehicle_loadout.rb` | Fit validation (`item_list_fits`, `modules_fit`) |
| `app/models/vehicle_loadout_item.rb` | `ITEM_TYPES` |
| `app/models/hardpoint.rb`, `hardpoint_build.rb` | Slot tree, per-build size/types |
| `app/models/component.rb` | Size, category, `type_data` stats |
| `app/models/model_module.rb` | `unfit_everywhere` cascade to mirror |
| `app/lib/model_defenses.rb` | Existing server-side shield aggregation |
| `app/views/api/v1/vehicle_loadouts/_base.jbuilder` | Item serialisation |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/index.vue` | Editor, coming-soon tabs |
| `app/frontend/frontend/composables/useModuleSockets.ts` | Socket adapter pattern |
| `app/frontend/frontend/composables/useFittingDiff.ts` | Client diff to replace |
| `app/frontend/frontend/components/Vehicles/LoadoutView/index.vue` | Read view |
| `app/frontend/frontend/composables/useEquippedHardpoints.ts` | Ship page graft (#5713) |
| `docs/findings/sc-data-builds.md` | Loadout constraints across builds |

## Not in scope (deferred)

- **Paint in the loadout.** Tracked in #5716.
- **Tag-based fit rules** (`port_tags`/`required_tags`). Deferred by decision; becomes its own issue before the PR merges.
- **Per-source validity report on read**, as described in `sc-data-builds.md`. It becomes its own issue unless it falls out of the resolver.

## Discovery Log

- **2026-10-17** Initial research and plan creation. Ownership for modules was settled in #5710 ("a loadout is a plan"). No fit-compatibility logic exists yet. Stats are client-side, apart from `ModelDefenses`.
- **2026-10-17** Two hardpoint trees answer a slot path. A component's own ports (`parent_type: Component`) carry types, size range and flags but no stock part; the ship's copy (`parent_type: Hardpoint`) carries the stock parts but no types, and its sizes are the installed part's (the Hornet Mk II nose turret's gun ports read 3-3 on the ship, 2-3 on the turret). `LoadoutSlots` reads rules from the port and stock from the copy.
- **2026-10-17** The items loader never wrote build rows for component ports: only the 4.10.0 backfill had them, so `in_build` hid every one on later builds. Fixed in this branch; production needs an items re-load (not a re-parse) before swapped mounts show their ports.
- **2026-10-17** Hull port sizes are the installed part's size (`slot_sizes` in the base loader), so a hull slot never takes a bigger part than it ships with. Conservative, left alone.
- **2026-10-17** Tractor beams are typed `WeaponGun`, so a type-and-size check offers them for gun ports. Only port tags tell them apart, and tags are deferred.
- **2026-10-17** Uneditable ports (flag `uneditable`) take only their stock part; what sits inside them stays fittable. 238 of 518 hull weapon mounts carry it.

## Progress

- [x] Phase 1: Fitting model (#5770)
- [x] Phase 2: API (#5770)
- [ ] Phase 3: Server-side stats + diff (#5771)
- [ ] Phase 4: Editor (#5772)
- [ ] Phase 5: Read view + pages (#5772)
