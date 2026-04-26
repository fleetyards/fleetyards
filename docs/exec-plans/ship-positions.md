# Ship Position System

## Context

The mission builder needs to reference crew positions on ships, but there's no reliable position data. The current approach (walking hardpoints in the frontend, detecting seats and manned turrets client-side) is fragile — it produces "Unknown" labels, misses jumpseats, and breaks when the FilterGroup re-emits. We need a proper server-side `ModelPosition` model that's auto-generated from SC data and can be curated by admins.

Resolves #3791.

## Data Model

### `model_positions`

| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK |
| model_id | uuid | FK → models, NOT NULL |
| name | string | NOT NULL ("Pilot", "Turret Gunner 1", "Loadmaster") |
| position_type | integer | NOT NULL, enum |
| hardpoint_id | uuid | FK → hardpoints, nullable (for SC-derived positions) |
| source | integer | NOT NULL, enum (sc_data, curated) |
| position | integer | NOT NULL, default: 0 (sort order) |
| timestamps | | |

Indexes: `(model_id)`, `(model_id, hardpoint_id)` unique where hardpoint_id not null

**position_type enum:**
```ruby
enum :position_type, {
  pilot: 0, copilot: 1, turret_gunner: 2, engineer: 3,
  gunner: 4, loadmaster: 5, passenger: 6, operator: 7, custom: 99
}
```

**source enum:**
```ruby
enum :source, { sc_data: 0, curated: 1 }
```

## Auto-Generation Logic

Runs after SC data import (hook into `ModelsLoader.load_model` after `update_loadout`).

For each in-game model:

1. **Seat hardpoints** (`group: :seat`, excluding `_access`):
   - `hardpoint_seat_pilot` → position_type: :pilot
   - `hardpoint_seat_copilot` → position_type: :copilot
   - `hardpoint_seat_*` → infer type from name, default :operator
   - `hardpoint_component_room_*_engineer_console` → position_type: :engineer
   - `hardpoint_turret_console_*` → position_type: :turret_gunner

2. **Manned turrets** (`component.name == "Manned Turret"`, no nested seat child):
   - Create position_type: :turret_gunner, name from `sc_name` (e.g. "Turret Top")

3. **Loadmaster** (if `max_crew > 1` AND model has cargogrid hardpoint):
   - Create position_type: :loadmaster, hardpoint_id: null

4. **Gap detection**: If auto-generated position count < `max_crew`, set `model.positions_need_curation = true` (boolean flag on models table)

**Key rule:** Only overwrite `source: :sc_data` positions on re-import. Positions with `source: :curated` survive re-imports.

### Name Derivation

```ruby
def self.derive_name(hardpoint)
  sc_name = hardpoint.sc_name
  return "Pilot" if sc_name.include?("_pilot")
  return "Copilot" if sc_name.include?("_copilot")
  if sc_name.include?("engineer_console")
    return sc_name.sub(/.*?_engineer_console/, "Engineer Console")
                  .sub(/^_/, "").tr("_", " ").titleize
  end
  if sc_name.start_with?("turret_")
    return sc_name.sub("turret_", "Turret ").tr("_", " ").titleize
  end
  if sc_name.include?("turret_console")
    return sc_name.sub(/.*turret_console/, "Turret Console")
                  .sub(/^_/, "").tr("_", " ").titleize
  end
  sc_name.sub(/^hardpoint_(seat_)?/, "").tr("_", " ").titleize
end
```

## Admin Curation

### Migration: Add `positions_need_curation` to models

```ruby
add_column :models, :positions_need_curation, :boolean, default: false
```

### Admin Controller

`Admin::Api::V1::ModelPositionsController`:
- `GET /admin/models/:slug/positions` — list positions for a model
- `POST /admin/models/:slug/positions` — add curated position
- `PUT /admin/models/:slug/positions/:id` — update position
- `DELETE /admin/models/:slug/positions/:id` — delete position
- `POST /admin/models/:slug/positions/regenerate` — re-run auto-generation (clears sc_data, keeps curated)

### Admin UI

Add to the existing admin model edit page:
- Positions section showing all positions (auto + curated)
- Add/edit/remove positions
- "Regenerate from SC data" button
- Badge showing "Needs curation" when `positions_need_curation` is true
- Filter for models needing curation in admin models list

## Public API

`GET /api/v1/models/:slug/positions` — returns positions for a model:
```json
[
  { "id": "uuid", "name": "Pilot", "positionType": "pilot", "source": "sc_data", "position": 0 },
  { "id": "uuid", "name": "Turret Top", "positionType": "turret_gunner", "source": "sc_data", "position": 1 },
  { "id": "uuid", "name": "Loadmaster", "positionType": "loadmaster", "source": "curated", "position": 5 }
]
```

## Integration Points

### Model Detail Page (frontend)
Replace the current seat display in the hardpoints component with a dedicated crew positions section showing position names with types.

### SC Data Import Hook
In `ModelsLoader.load_model`, after `update_loadout(model, model_data)`:
```ruby
ModelPosition.generate_for_model!(model)
```

### Future: Mission Builder
The mission builder will reference `ModelPosition` instead of walking hardpoints client-side. This replaces `MissionTeamVehicleSeat` with a proper server-side position reference.

## Implementation Phases

### Phase 1 — Migration, Model, Auto-Generation
- Create `model_positions` table
- Add `positions_need_curation` to models
- `ModelPosition` model with enums, validations, associations
- `ModelPosition.generate_for_model!(model)` class method
- Hook into ModelsLoader
- MaintenanceTask to generate positions for all existing models

### Phase 2 — Public API
- `Api::V1::ModelPositionsController` with index action
- JBuilder view
- API schema component
- RSpec request spec
- Generate OpenAPI schema

### Phase 3 — Admin API
- `Admin::Api::V1::ModelPositionsController` with CRUD + regenerate
- Admin policy
- Admin JBuilder views + API schemas
- RSpec specs

### Phase 4 — Frontend
- Ship detail page: replace seat hardpoints display with crew positions section
- Remove the current seat display from hardpoints component
- Admin model edit: positions management UI
- Admin models list: "needs curation" filter/badge
- Orval client regeneration

### Phase 5 — Data Quality
- Run generation for all models
- Identify and curate dropships (Valkyrie, Prowler, Hoplite)
- Review models flagged as needs_curation
- Verify position counts match max_crew where possible

## Files to Create/Modify

**Create:**
- `db/migrate/xxx_create_model_positions.rb`
- `app/models/model_position.rb`
- `app/controllers/api/v1/model_positions_controller.rb`
- `app/controllers/admin/api/v1/model_positions_controller.rb`
- `app/policies/model_position_policy.rb`
- `app/views/api/v1/model_positions/`
- `app/api_components/v1/schemas/models/model_position.rb`
- `spec/requests/api/v1/model_positions/`
- `spec/factories/model_positions.rb`
- `app/tasks/maintenance/generate_model_positions_task.rb`
- Frontend: position components + admin UI

**Modify:**
- `app/models/model.rb` — add `has_many :model_positions` + `positions_need_curation`
- `app/lib/sc_data/loader/models_loader.rb` — hook position generation
- `app/frontend/frontend/components/Models/Hardpoints/` — remove seat display, add positions
- Admin routes, admin model views

## Verification

1. Run MaintenanceTask → positions auto-generated for all models
2. `bundle exec rspec spec/requests/api/v1/model_positions/` → specs pass
3. `GET /api/v1/models/aegs-hammerhead/positions` → returns pilot, copilot, 6 turret gunners, 2 engineers, captain's quarters, loadmaster
4. Admin: edit Valkyrie → add 20 passenger jumpseats → re-import SC data → jumpseats preserved
5. Ship detail page shows crew positions instead of seat hardpoints
