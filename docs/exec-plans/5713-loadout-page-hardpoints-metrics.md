# Loadout page with hardpoints and metrics

Working plan for #5713. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A page per vehicle loadout showing the ship detail page's hardpoints and metrics sections fed by the loadout's fitting, with the ship's fuel draw and endurance at full thrust.

## Open questions

- The fuel intake's `fuelPushRate` unit (25 on 19 intakes, 0 on the Scorpius's): needed before the endurance can be net of refuelling.

## What changed

### Phase 1 — Fuel figures (hull-level, shown on the ship page too)
1. Serialize `fuel_consumption` (all thrusters, µSCU/s at full thrust) with the model's speeds; add the main-thrusters-only draw.
2. Endurance at full thrust: hydrogen tank size over the draw, main thrusters first, all thrusters second.
3. Show both in `Models/FlightMetrics`' Fuel section.

### Phase 2 — Hardpoints and metrics fed by a fitting
1. `Models/Hardpoints` takes an optional fitting (the grafted hardpoints and the fitted modules) in place of its own fetch and module picks; the list reads the grafted hardpoints, not the raw ones.
2. In loadout mode, module slots are read-only and the source switch is hidden.

### Phase 3 — The page
1. Route `hangar-vehicle-loadout` at `:username/:segment/loadouts/:loadout/`, file `pages/hangar/[username]/[segment]/loadouts/[loadout].vue`, added to `VehicleRouteName`.
2. Build the fitting as `LoadoutView` does: loadout slots, hull slots, game-files hardpoints, modules; learn, resolve, graft.
3. The owner gets "Edit loadout" into the editor.

### Phase 4 — Visitors
1. A public read endpoint for a loadout and its slots, gated like the plaque (`purchased.public`, the owner's `vehicle_overview`).
2. A route outside the owner guard, read-only.

### Phase 5 — Links
1. The hero's loadout badge, `LoadoutView`'s footer and the loadouts list rows link to the page.

## Intent Verification

- [ ] **A page per vehicle loadout** with the ship page's hardpoints and metrics, reached from the loadouts list
- [ ] **The hardpoints reflect the fitting**: modules in their slots with their hardpoints grafted in, swapped and emptied components in theirs
- [ ] **The metrics reflect the fitting**
- [ ] **Visitors see it read-only; the owner can edit**
- [ ] **The loadout marker and the read view link to it**
- [ ] **Fuel draw and endurance at full thrust** shown beside the flight figures

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/hangar/[username]/[segment]/routes.ts` | Vehicle tab routes |
| `app/frontend/frontend/pages/hangar/routes.ts` | Vehicle shell, owner guard, cargo drill-in precedent |
| `app/frontend/frontend/components/Models/Hardpoints/index.vue` | Hardpoints and metrics section |
| `app/frontend/frontend/composables/useEquippedHardpoints.ts` | Module grafting on the ship page |
| `app/frontend/frontend/composables/useComponentFitting.ts` | learn, resolve, graft |
| `app/frontend/frontend/components/Vehicles/LoadoutView/index.vue` | The fitting recipe to reuse |
| `app/frontend/frontend/components/Models/FlightMetrics/index.vue` | Fuel section |
| `app/views/api/v1/models/_base.jbuilder` | Model speeds |
| `app/controllers/api/v1/vehicle_loadouts_controller.rb` | Owner-only loadout endpoints |

## Not in scope (deferred)

- **Showing acceleration** (`mainAcceleration`, `secondsToScmSpeed` are serialized but shown nowhere) — unrelated to the fitting.

## Discovery Log

- **2026-10-18** Initial research and plan creation. Branched off `feat/5772-loadout-component-editor` (#5775), which the page needs: the unified hardpoint rows and the shared diff.

## Progress

- [x] Phase 1 — worked out in the browser from the fitted hardpoints (`composables/fuelDraw.ts`), so the loadout page follows its fitting; the endurance leaves the intakes out until their rate is understood
- [x] Phase 2 — `fitting` prop on `Models/Hardpoints`; module slots render as read-only rows with their fitted contents (`hardpointsReadOnly`)
- [x] Phase 3 — one route for owner and visitor (no owner guard); `useLoadoutFitting` shared with the read view
- [x] Phase 4 — `GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id(/slots)`, gated by `PublicHangarOwnerConcern`
- [ ] Phase 5
