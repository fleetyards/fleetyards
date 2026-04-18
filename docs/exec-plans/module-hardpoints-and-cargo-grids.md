# Exec Plan: Module Hardpoints & Cargo Grids on Model Detail Page

## Problem

When a model has module slots (e.g. Aurora Mk II, Retaliator), the model detail page doesn't show what those modules add. The hardpoints display shows MODULE category slots but doesn't expand to reveal the module's own hardpoints (weapons, shields, cargo grids, etc.). The cargo grid viewer also only considers the model's direct cargo holds, ignoring cargo added by modules.

## Current State

### Hardpoints Display
- `HardpointCategory` (category MODULE) renders module slots with a puzzle icon
- `HardpointBaseItem` supports nested hardpoints via `hardpoint.hardpoints` and `hardpoint.component.hardpoints`
- But module slots don't carry the module's hardpoints as sub-items — the data simply isn't linked

### Modules List
- `ModulesList` renders separately below hardpoints on the model detail page (`ships/[slug]/index.vue:430`)
- `ModulePanel` already renders each module's hardpoints grouped by category using `HardpointCategory`
- The module API response (`_base.jbuilder:40-42`) already includes `model_module.hardpoints`
- `ModelModule` has `cargo_holds` (YAML serialized) but this field is **not included** in the API response — only `cargo` (decimal total) is serialized under `metrics`

### Cargo Grid Viewer
- `CargoGridViewer` accepts `cargoHolds: CargoHold[]` prop
- Cargo grids page (`tools/cargo-grids.vue`) passes `selectedModel.cargoHolds` directly
- `ModelCargoMetrics` on model detail page also uses `model.cargoHolds` only
- No awareness of module-contributed cargo holds

## Plan

### Phase 1: Include `cargo_holds` in the Module API Response

**File:** `app/views/api/v1/model_modules/_base.jbuilder`

Add `cargo_holds` to the module serializer (similar to how `app/views/api/v1/models/_base.jbuilder:120` does it for models):

```ruby
json.cargo_holds model_module.cargo_holds
```

This makes module cargo hold data (dimensions, capacity, max container size) available to the frontend. The `ModelModule` TypeScript type already has `cargoHolds?: CargoHold[]` defined.

### Phase 2: Cargo Grid Viewer — Include Module Cargo Holds

**File:** `app/frontend/frontend/pages/tools/cargo-grids.vue`

When a model is selected and has modules, fetch the model's modules and merge their `cargoHolds` into the viewer:

1. After selecting a model, also fetch its modules via `useModelModules(slug)`
2. Combine `model.cargoHolds` + all module `cargoHolds` into a single array
3. Pass the combined array to `<CargoGridViewer>`
4. The `computeGreedyFill()` function already handles multiple holds — no changes needed there

The cargo grid viewer should only show module cargo holds when the user has equipped modules (see Phase 3 for the equip UI). The equipped module selection state drives what cargo holds are passed to the viewer.

1. Combine `model.cargoHolds` + equipped modules' `cargoHolds` into a single array
2. Pass the combined array to `<CargoGridViewer>`
3. The `computeGreedyFill()` function already handles multiple holds — no changes needed there
4. Module holds could use a `module_` prefix in their name to visually separate them via the existing `groupCargoHolds()` utility

**File:** `app/frontend/frontend/components/Models/CargoMetrics/index.vue`

Similarly update the cargo metrics summary to reflect base cargo + cargo from equipped modules.

### Phase 3: Hardpoints Display — Show Module Contents in Module Slots

This is the more complex change. Two approaches:

Make MODULE category hardpoints into equip slots. Each slot shows a dropdown/selector of compatible modules. The user picks which module to equip, and the slot expands (collapsed by default) to reveal that module's hardpoints. The equipped module selection also drives the cargo grid viewer and cargo metrics.

**Files:**
- `app/frontend/frontend/components/Models/Hardpoints/Items/index.vue` — Add a new item type for MODULE category (like `HardpointCargoItem` for CARGOGRID)
- New component: `app/frontend/frontend/components/Models/Hardpoints/ModuleItem/index.vue`
  - Receives the module slot hardpoint and the list of available modules for this model
  - Renders a module selector (dropdown) to let the user choose which module to equip in this slot
  - When a module is selected, shows a collapsed section that can be expanded to reveal the module's hardpoints via existing `HardpointCategory`
  - Emits the equipped module selection upward so it can feed into cargo grid viewer

**State management:**
- `equippedModules: Record<slotId, ModelModule | null>` — tracks which module is equipped in each slot
- Lifted to the model detail page level or managed via provide/inject
- Drives both the hardpoint expansion display and the cargo holds passed to CargoGridViewer/CargoMetrics

Data flow:
1. Model detail page fetches modules (already does via `ModulesList`)
2. Provide modules data + equipped state to the hardpoints section (via provide/inject)
3. `ModuleItem` renders a module selector per slot; collapsed by default
4. User selects a module → state updates → hardpoint details become expandable
5. Equipped modules' `cargoHolds` are merged with model's base `cargoHolds` for the cargo viewer

### Phase 4: Model Detail Page — Provide Module Data to Hardpoints

**File:** `app/frontend/frontend/pages/ships/[slug]/index.vue`

Currently `ModulesList` and `Hardpoints` are sibling components that don't share data. To avoid duplicate API calls:

1. Lift the `useModelModules` query up to the detail page level
2. Pass the modules data down to both `Hardpoints` (for inline module display) and `ModulesList`
3. Or use provide/inject to make modules available to the hardpoints tree

## File Change Summary

| File | Change |
|------|--------|
| `app/views/api/v1/model_modules/_base.jbuilder` | Add `cargo_holds` serialization |
| `app/frontend/frontend/pages/ships/[slug]/index.vue` | Lift module query, pass to hardpoints |
| `app/frontend/frontend/pages/tools/cargo-grids.vue` | Merge module cargo holds into viewer |
| `app/frontend/frontend/components/Models/CargoMetrics/index.vue` | Account for module cargo in metrics |
| `app/frontend/frontend/components/Models/Hardpoints/new.vue` | Accept modules prop |
| `app/frontend/frontend/components/Models/Hardpoints/Items/index.vue` | Route MODULE category to new component |
| `app/frontend/frontend/components/Models/Hardpoints/ModuleItem/index.vue` | **New** — module equip selector + collapsible hardpoint display |

## Decisions

1. **Cargo grid viewer**: Only shows module cargo holds when the user has equipped modules — not by default
2. **Module hardpoints**: Collapsed by default, user expands to see details
3. **Multiple modules per slot**: User picks which module to equip via a selector dropdown (e.g. Retaliator front slot: choose between torpedo bay, cargo module, living module, or dropship module)
