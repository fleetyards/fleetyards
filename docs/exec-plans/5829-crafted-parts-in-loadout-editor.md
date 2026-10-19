# Crafted parts in the loadout editor

Working plan for #5829. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A fitted component with a blueprint can be marked crafted in the loadout editor, with a quality per recipe slot, saved on the loadout item, and every loadout figure reads the crafted values.

## What changed

### Phase 1 — Backend: store and validate crafted items
1. Migration: `vehicle_loadout_items.blueprint_id` (uuid, FK, nullable) and `crafted_qualities` (jsonb, `{position => quality}`, default `{}`).
2. `VehicleLoadout#item_list=` carries `crafted: {blueprint_id:, qualities: [{position:, quality:}]}`; `crafted_items_fit` refuses a blueprint on a non-component, a blueprint that does not make the part in the build in force, a position the recipe does not have, and a quality outside 0–1000 (codes in all 7 locales).
3. Controller permits the nested params; `_base.jbuilder` renders `crafted: {blueprintId, blueprintSlug, qualities}`; cache key bumped (loadout + vehicle partials).
4. API components: `VehicleLoadoutItemCrafted`, `VehicleLoadoutItemCraftedInput`, `CraftedSlotQuality`; schema + clients regenerated.
5. Tests: model validation, create/update/show integration.

### Phase 2 — Frontend: crafted figures
1. `craftedComponent(component, costSlots, qualityFor)`: scales `typeData` fields by the composed factor per `propertyKey` (mirrors `BlueprintStatBases::COMPONENT` + weapon damage per type). Factors compose by multiplying, as `useCraftedStats` does.
2. `useComponentFitting.resolve` takes the crafted map and puts the crafted copy on `content`; socket `changed` and stacking signature account for crafting; socket item shows a crafted badge.
3. Recipes fetched by blueprint slug (`useCraftedRecipes`), one request per recipe.

### Phase 3 — Frontend: editor UI
1. Form field `craftedComponents: Record<slotPath, {blueprintId, blueprintSlug, qualities}>`; picking another part drops the slot's crafting.
2. A crafting panel in the picker for the active socket's part: "Crafted" toggle (only when the part has a blueprint), quick-set presets, per-slot quality using `BlueprintSlot`.
3. Save sends `crafted` per component item, keeping a crafted stock part as an explicit item.
4. Read-only views (`useLoadoutFitting`) apply crafting.
5. Specs.

## Intent Verification

- [ ] Toggle crafted on a fitted shield, set qualities to 1000 → shield HP figure rises in metrics and changes card
- [ ] Save, reopen → qualities restored; loadout page shows crafted figures
- [ ] Part without blueprint shows no crafted toggle
- [ ] API refuses invalid crafted payloads with the specific codes

## Key files

| File | Role |
|------|------|
| `app/models/vehicle_loadout.rb` | item list write + validation |
| `app/views/api/v1/vehicle_loadouts/_base.jbuilder` | item rendering |
| `app/api_components/v1/schemas/vehicles/vehicle_loadout_item.rb` | output schema |
| `app/lib/blueprint_stat_bases.rb` | propertyKey → stat field mapping (Ruby) |
| `app/frontend/frontend/composables/useComponentFitting.ts` | fitted content resolution |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/index.vue` | editor state + save |
| `app/frontend/frontend/components/Blueprints/Slot/index.vue` | per-slot quality UI |

## Not in scope (deferred)
- **Power-pip modifiers carry no figures** — the parser reads only `modifierAtStart/End`; additive ramps use `additiveModifierAtStart/End`. Needs a parser change and a re-parse; crafted power plants keep catalogue pips until then.

## Discovery Log

- **2026-10-19** Initial research and plan creation. Recipe and stat mapping exist only for the blueprint page; no component payload names its blueprint.
- **2026-10-19** The editor finds a part's recipe through the blueprint list filtered by craftable, as the component page does; the item stores the blueprint id and renders its slug so read-only views fetch the recipe by slug. The "open the recipe" link was dropped: it would navigate away from an unsaved editor.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Review
