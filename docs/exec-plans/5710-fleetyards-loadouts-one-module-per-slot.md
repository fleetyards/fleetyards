# Fleetyards loadouts: fit one owned module per slot

Working plan for #5710. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A vehicle's active fleetyards loadout records which owned module is fitted in each module slot, and the loadout editor edits it with one pick per slot.

## Open questions

- none open; see the issue's Decisions

## What changed

### Phase 1 — Slot backfill
1. Data migration: set `module_hardpoints.slot` from `ModuleHardpoint.derive_slot` where it is nil. Locally that resolves 21 of 27 unslotted links (Apollo Medivac/Triage, Retaliator); Galaxy and Endeavor stay nil because the game files have no module slots for them.

### Phase 2 — Model and table
1. Migration: `vehicle_loadouts.kind` (string, not null, default `"link"`), and `vehicle_loadout_items` (`vehicle_loadout_id` FK on delete cascade, `slot` not null, `model_module_id` FK, timestamps, unique `(vehicle_loadout_id, slot)`).
2. `VehicleLoadout`: `kind` enum `link`/`fleetyards`; `url` required for `link` and absent for `fleetyards`; items only on `fleetyards`; vehicle's model must be flight-ready (both kinds); `has_many :items`, accepts a replace-all items list; default name "Fleetyards Loadout" for the fleetyards kind.
3. `VehicleLoadoutItem`: `belongs_to :vehicle_loadout, touch: true`, `belongs_to :model_module`; validates the module is owned by the vehicle and that the module's `module_hardpoints.slot` on the vehicle's model equals `slot` (so an unslotted module cannot be fitted).
4. Pruning: when the vehicle's owned modules are replaced (`VehiclesController#update`), drop items whose module is no longer owned.
5. Items are not versioned (replaced wholesale on every save, like `vehicle_modules`); bulk vehicle delete keeps working via the cascade.

### Phase 3 — API
1. Controller permits `kind` and `items: [slot, modelModuleId]`.
2. Views render `kind` and `items`; preload items in `Vehicle.rendered_associations` and fleet vehicles.
3. Schemas: `VehicleLoadout`/`VehicleLoadoutMinimal` gain `kind` + `items`, `url` no longer required; new `VehicleLoadoutItem` and input item schemas; `VehicleLoadoutInput` gains `kind` + `items`.
4. Integration tests for create/update with items, the validation 400s, and the flight-ready rule; `bin/generate-schema`, `bin/generate-asyncapi`, oasdiff ignore entries for `url` leaving `required`.
5. Validation error messages in all 7 `validation_error.yml` locales.

### Phase 4 — Frontend
1. Loadout editor Modules tab: owned modules stay editable as today; a "Fitted" section per slot offers one pick among owned modules of that slot. Unslotted owned modules are listed as not fittable. Non-flight-ready ships get no fitting section.
2. Save: owned changes go through the vehicle update as today; fitted changes update the active fleetyards loadout, or create and activate one when there is none.
3. Stats in the editor use the fitted modules.
4. `LoadoutsCard`, `LoadoutMarker`, hangar loadouts page handle a loadout without a url.
5. Locale keys in all 7 locales.

## Intent Verification

- [ ] **One per slot** — a second item for the same slot is rejected by the API and impossible in the editor
- [ ] **Owned only** — fitting a module the vehicle does not own is rejected
- [ ] **Unslotted not fittable** — a Galaxy module cannot be fitted
- [ ] **Flight-ready only** — creating a loadout of either kind on an in-concept ship is rejected
- [ ] **Exclusive kinds** — a link loadout with items, or a fleetyards loadout with a url, is rejected
- [ ] **One active** — activating a fleetyards loadout deactivates an active link
- [ ] **No default** — a vehicle without a loadout has nothing fitted; the editor's cargo shows the hull only
- [ ] **Stale items pruned** — removing an owned module removes its fitted item

## Key files

| File | Role |
|------|------|
| `app/models/vehicle_loadout.rb` | kind, validations, items |
| `app/models/module_hardpoint.rb` | `derive_slot`, slot source |
| `app/controllers/api/v1/vehicle_loadouts_controller.rb` | params |
| `app/controllers/api/v1/vehicles_controller.rb` | owned module replace → prune |
| `app/api_components/v1/schemas/vehicles/vehicle_loadout*.rb`, `inputs/vehicle_loadout_input.rb` | schemas |
| `app/views/api/v1/vehicle_loadouts/_base.jbuilder` | payload |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/` | editor |
| `app/frontend/frontend/components/Vehicles/Overview/LoadoutsCard/index.vue`, `shared/components/LoadoutMarker/index.vue`, `pages/hangar/[username]/[segment]/loadouts.vue` | url-less loadouts |

## Shape after the reshape

- `vehicle_loadout_items`: `slot_path` (hardpoint names from the hull down, `/`-joined) + polymorphic `item` (`ModelModule` only, `VehicleLoadoutItem::ITEM_TYPES`). A nested path needs its parent path fitted; unfitting a module drops what sits under it.
- Loadout editor (`LoadoutModal`): one fleetyards loadout (by `loadoutId`, `newLoadout`, or the active one), name + fitting, one Save. Category tabs only; nothing owned is edited there.
- Vehicle editor (`EditModal`): Modules / Upgrades / Paint tabs for what the ship owns (`Addons`, `Packages` moved here).
- Loadouts page: "Edit loadout" on a fleetyards row, "New loadout" button.

## Not in scope (deferred)
- **Loadout page with hardpoints and metrics** — #5713. The modal read view covers the marker until then.
- **Components per hardpoint** — #5714. The other "coming soon" tabs; they reuse `vehicle_loadout_items` with a component item.
- **Ship detail page's role** — #5715. Information only, or loadouts shown there too.
- **Owned paints and paint pictures in the gallery** — #5716. The Paint tab still sets the single applied paint.
- **Paint in the loadout** — after the component categories work.
- **Admin UI for module slots** — the admin API takes `slot`; a form for it is separate.

## Discovery Log

- **2026-10-15** Initial research. `module_hardpoints.slot` was never backfilled: 27 of 33 links nil locally; 21 derivable. Galaxy and Endeavor have no game-file module hardpoints. `ModelsController#modules` maps one slot per module (`.to_h`). All 383 existing loadouts are links on flight-ready ships. `groupKey` and hardpoint ids are not stable; persist `sc_name`.
- **2026-10-15** `url`/`urlSource` are omitted on a fleetyards loadout rather than sent as null: null would have made both nullable across 19 endpoints in oasdiff; omitted leaves only "url became optional" (19 ignore entries, from the pinned oasdiff 1.18.1).
- **2026-10-15** `VehiclesController#update` reloads `vehicle_loadouts` after unfitting, or the response renders the loadout it had cached before the prune.
- **2026-10-15** The editor fixes from main (FormTabs render loop, tab clarity, module cargo in Specs) were uncommitted there; carried over as their own commits because the fitting builds on them.

## Progress
- [x] Phase 1 — Slot backfill
- [x] Phase 2 — Model and table
- [x] Phase 3 — API
- [x] Phase 4 — Frontend
- [x] Stock modules fittable without being owned
- [x] Explicit save; saved loadouts editable
- [x] Reshape: one loadout per editor; owned equipment in the vehicle editor; slot paths + polymorphic items
- [ ] Live check in a running app (not done: needs a dev server on this branch)
