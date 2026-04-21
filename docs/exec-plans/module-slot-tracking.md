# Exec Plan: Module Slot Tracking on module_hardpoints

## Problem

`module_hardpoints` is a bare join table (`model_id`, `model_module_id`, timestamps) with no slot/position info. All possible modules are linked to a model during import, but some modules are mutually exclusive — they compete for the same physical slot on the ship.

**Concrete example:** The Retaliator has 2 module slots (front, rear). Each slot has 4 possible modules (torpedo bay, cargo, living, dropship). All 8 modules are linked via `module_hardpoints`. The cargo finder (`CargoFinderSql`) sums ALL module cargo holds optimistically:

```sql
SELECT SUM(mm.cargo) FROM model_modules mm
INNER JOIN module_hardpoints mh ON mh.model_module_id = mm.id
WHERE mh.model_id = models.id ...
```

This produces false positives: a Retaliator with front cargo (36 SCU) + rear cargo (36 SCU) is correctly 72 SCU total, but the finder also counts the other modules, treating all 8 as simultaneously equipped.

**Ships affected:** Retaliator (2 slots), Cyclone variants (1 slot), Spartan (1 slot), MPUV (1 slot), Mustang variants (1 slot).

## Current State

### SC Data
Module slot names are available in the ship's loadout data and encode position:
- Retaliator: `hardpoint_front_module`, `hardpoint_rear_module`
- Cyclone/Spartan: `hardpoint_module_attach`
- MPUV: `hardpoint_module`
- Mustang: `hardpoint_cargo_module`

### Frontend
`ModuleItem` already infers slot from hardpoint name using keyword heuristics (`front`, `rear`, `bow`, `stern`) — see `app/frontend/frontend/components/Models/Hardpoints/ModuleItem/index.vue:52-57`. The `equippedModules` state is keyed by `slotId` (hardpoint `groupKey` or `id`).

### Import
`modules_importer.rb:175-178` creates `ModuleHardpoint` with just `model_id` + `model_module_id`. The SC data loader (`base_loader.rb:80-166`) creates `Hardpoint` records for the model that include the `sc_name` (e.g. `hardpoint_front_module`), but this info is not carried to `module_hardpoints`.

## Plan

### Phase 1: Migration — Add `slot` Column

**File:** New migration

Add a `slot` string column to `module_hardpoints`:

```ruby
add_column :module_hardpoints, :slot, :string
add_index :module_hardpoints, [:model_id, :slot]
```

The `slot` value is the hardpoint `sc_name` from SC data (e.g. `hardpoint_front_module`, `hardpoint_rear_module`). Using the full sc_name rather than extracting "front"/"rear" keeps it unambiguous and 1:1 with the source data.

### Phase 2: Populate Slot Data

**File:** New Rake task or data migration

For existing records, derive the slot from the model's `Hardpoint` records where `category: :module`:

```ruby
Model.joins(:module_hardpoints).distinct.find_each do |model|
  module_slots = model.hardpoints.where(category: :module, source: :game_files)

  model.module_hardpoints.find_each do |mh|
    mod = mh.model_module
    next if mod.blank?

    # Match module to slot by checking which slot's default component matches,
    # or by matching position keywords (front/rear) between slot name and module sc_key
    slot = module_slots.find do |hp|
      mod_key = (mod.sc_key || "").downcase
      hp_name = hp.sc_name || ""

      # Direct match: slot's component is this module
      hp.component&.sc_key&.downcase == mod_key ||
        # Position match: both contain "front", "rear", etc.
        %w[front rear bow stern].any? { |kw| hp_name.include?(kw) && mod_key.include?(kw) }
    end

    # Fallback for single-slot ships (Cyclone, Mustang, etc.)
    slot ||= module_slots.first if module_slots.count == 1

    mh.update!(slot: slot&.sc_name) if slot.present?
  end
end
```

### Phase 3: Import — Set Slot on Creation

**File:** `app/lib/modules_importer.rb`

When creating `ModuleHardpoint` records, also look up the matching module slot hardpoint on the model and set the `slot` field:

```ruby
# After finding the model and model_module (around line 175)
module_slot = model.hardpoints.find_by(category: :module, source: :game_files, sc_name: derive_slot_name(model, model_module))

ModuleHardpoint.create!(
  model_id: model.id,
  model_module_id: model_module.id,
  slot: module_slot&.sc_name
)
```

The `derive_slot_name` method matches module to slot using the same position-keyword logic as Phase 2. Extract the shared logic into a concern or class method on `ModuleHardpoint`.

**File:** `app/controllers/admin/api/v1/model_modules_controller.rb`

Add `slot` to the link action params so admins can manually set it:

```ruby
ModuleHardpoint.find_or_create_by!(
  model_id: model.id,
  model_module_id: model_module.id,
  slot: params[:slot]
)
```

### Phase 4: API — Expose Slot

**File:** `app/views/api/v1/models/_base.jbuilder` (or wherever module_hardpoints are serialized)

Include `slot` in the module association response so the frontend can use it instead of name heuristics.

**File:** `app/views/admin/api/v1/model_modules/_base.jbuilder`

Include `slot` in admin API responses.

### Phase 5: CargoFinderSql — Respect Slot Exclusivity

**File:** `app/lib/sc_data/cargo_finder_sql.rb`

Replace the optimistic `MODULE_CARGO_SQL` with slot-aware logic. For each slot, count only the maximum cargo among the modules in that slot (conservative estimate for the finder):

```ruby
MODULE_CARGO_SQL = <<~SQL.squish
  COALESCE((
    SELECT SUM(max_cargo_per_slot) FROM (
      SELECT mh.slot, MAX(mm.cargo) AS max_cargo_per_slot
      FROM model_modules mm
      INNER JOIN module_hardpoints mh ON mh.model_module_id = mm.id
      WHERE mh.model_id = models.id AND mm.cargo IS NOT NULL AND mm.cargo > 0
      GROUP BY mh.slot
    ) slot_groups
  ), 0)
SQL
```

This groups modules by slot and takes the MAX cargo per slot instead of SUM across all modules. For the Retaliator: max(front cargo 36, front torpedo 0, front living 0, front dropship 0) + max(rear cargo 36, ...) = 72 SCU max, not 72+.

Similarly update `CARGO_HOLDS_FOR_MODEL_SQL` to only include cargo holds from the highest-cargo module per slot, or accept a "selected modules" parameter.

Update `all_cargo_holds_for(model)` to accept an optional `equipped_modules` hash (slot → module_id) for precise filtering when the user has made explicit choices (e.g. from the ship detail page).

### Phase 6: Frontend — Use Slot from API

**File:** `app/frontend/frontend/components/Models/Hardpoints/ModuleItem/index.vue`

Replace the heuristic `slotPosition` computed with actual slot data from the API when available, falling back to the current keyword matching:

```typescript
const slotId = computed(() => {
  // Prefer slot from module_hardpoint data if available
  return hardpoint.value.moduleSlot || hardpoint.value.groupKey || hardpoint.value.id;
});
```

This is a progressive enhancement — the heuristic fallback keeps things working for any models where slot data isn't populated yet.

## File Change Summary

| File | Change |
|------|--------|
| New migration | Add `slot` column + index to `module_hardpoints` |
| New Rake task / data migration | Backfill slot for existing records |
| `app/models/module_hardpoint.rb` | Add `slot` to ransackable_attributes, add `derive_slot` class method |
| `app/lib/modules_importer.rb` | Set `slot` when creating ModuleHardpoint |
| `app/controllers/admin/api/v1/model_modules_controller.rb` | Accept `slot` param in link action |
| `app/views/api/v1/models/_base.jbuilder` | Include slot in module serialization |
| `app/views/admin/api/v1/model_modules/_base.jbuilder` | Include slot in admin API |
| `app/lib/sc_data/cargo_finder_sql.rb` | Slot-aware MODULE_CARGO_SQL, update `all_cargo_holds_for` |
| `app/frontend/.../ModuleItem/index.vue` | Use slot from API, keep heuristic fallback |

## Decisions

1. **Slot value format**: Use the full hardpoint `sc_name` (e.g. `hardpoint_front_module`) rather than extracted keywords. Keeps it unambiguous and directly traceable to SC data.
2. **Cargo finder strategy**: Use MAX(cargo) per slot as the default estimate. This is a conservative optimistic bound — it assumes the user equips the highest-cargo module for each slot. For precise results (e.g. ship detail page), accept explicit equipped module choices.
3. **Null slot handling**: Modules with `slot: nil` (not yet backfilled) are treated as independent (no grouping) — backward compatible with current behavior.
4. **No unique constraint** on `(model_id, slot)`: Multiple modules share a slot (they're alternatives, not simultaneously equipped).
