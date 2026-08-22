# Mission Builder v3 — Templates Phase

A fleet tool for creating reusable mission templates. Templates organize the mission into **teams** (logical groupings) and **ships** (specific vehicles needed). Both teams and ships contain **slots** that participants can later fill.

Scoped to the **template authoring** experience only. Scheduling concrete events, Discord integration, and sign-ups are explicit future phases (not in this plan).

## Concepts

| Term | Description |
|------|-------------|
| **Mission** | Reusable template owned by a fleet. The top-level container. |
| **Mission Team** | A logical group of participants (e.g. "Strike Team", "Recovery Team"). Has slots. |
| **Mission Ship** | A specific ship model required for the mission (e.g. "Hammerhead"). Has slots (e.g. "Pilot", "Turret 1"). |
| **Mission Slot** | A single position to be filled by a participant. Belongs polymorphically to a team OR a ship. |

Future phases (out of scope for this plan): fleet events, sign-ups, Discord webhooks, lifecycle/AASM, ship-attribute filters on slots (classification/focus/size).

## Data Model

UUID PKs throughout. All migrations use `id: :uuid`.

### `missions`

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `fleet_id` | uuid | FK → fleets, NOT NULL |
| `created_by_id` | uuid | FK → users, NOT NULL |
| `title` | string | NOT NULL |
| `description` | text | |
| `slug` | string | NOT NULL, unique within fleet |
| `archived_at` | datetime | nullable |
| `created_at`/`updated_at` | datetime | |

**Indexes:** `(fleet_id)`, unique `(fleet_id, slug)`

### `mission_teams`

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `mission_id` | uuid | FK, NOT NULL |
| `title` | string | NOT NULL |
| `description` | text | |
| `rank` | text | NOT NULL (lexorank) |
| `created_at`/`updated_at` | datetime | |

**Indexes:** `(mission_id)`

### `mission_ships`

A ship slot supports **two modes**:
- **Strict** — `model_id` set, references one specific Model (e.g. "Constellation Andromeda")
- **Range** — filter columns set, matches any Model meeting the criteria (e.g. "Combat ship, size large+, min crew 4")

At template authoring time both modes are valid. When a Fleet Event is later spawned from the template (future phase), range slots will be resolved to a concrete Model by the event organizer or by the participant signing up.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `mission_id` | uuid | FK, NOT NULL |
| `model_id` | uuid | FK → models, nullable |
| `title` | string | optional label; falls back to `model.name` or auto-generated from filters |
| `description` | text | |
| `classification` | string | nullable — Combat / Industrial / Multi-Role / Exploration / Transporter / Support |
| `focus` | string | nullable |
| `min_size` | string | nullable — snub/small/medium/large/extra_large/capital |
| `max_size` | string | nullable |
| `min_crew` | integer | nullable |
| `min_cargo` | decimal | nullable |
| `rank` | text | NOT NULL (lexorank) |
| `created_at`/`updated_at` | datetime | |

**Validation:** must have either `model_id` OR at least one filter column set (enforced via model validation, not DB).

**Indexes:** `(mission_id)`, `(model_id)`

### `mission_slots` (polymorphic)

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `slottable_type` | string | NOT NULL — `MissionTeam` or `MissionShip` |
| `slottable_id` | uuid | NOT NULL |
| `title` | string | NOT NULL — e.g. "Pilot", "Combat Lead" |
| `description` | text | |
| `rank` | text | NOT NULL (lexorank, scoped to slottable) |
| `created_at`/`updated_at` | datetime | |

**Indexes:** `(slottable_type, slottable_id)`

## Models

```ruby
class Mission < ApplicationRecord
  include SlugConcern

  belongs_to :fleet
  belongs_to :created_by, class_name: "User"
  has_many :teams, class_name: "MissionTeam", dependent: :destroy
  has_many :ships, class_name: "MissionShip", dependent: :destroy

  validates :title, presence: true
  before_save { self.slug = generate_slug(title) if slug.blank? || title_changed? }

  scope :active, -> { where(archived_at: nil) }

  AVAILABLE_PRIVILEGES = %w[
    fleet:missions:read
    fleet:missions:create
    fleet:missions:update
    fleet:missions:delete
    fleet:missions:manage
  ].freeze
end

class MissionTeam < ApplicationRecord
  include Lexorank::Rankable
  rank! group_by: :mission

  belongs_to :mission
  has_many :slots, class_name: "MissionSlot", as: :slottable, dependent: :destroy

  validates :title, presence: true
end

class MissionShip < ApplicationRecord
  include Lexorank::Rankable
  rank! group_by: :mission

  belongs_to :mission
  belongs_to :model, optional: true
  has_many :slots, class_name: "MissionSlot", as: :slottable, dependent: :destroy

  def display_title
    title.presence || model&.name
  end
end

class MissionSlot < ApplicationRecord
  include Lexorank::Rankable
  rank! group_by: [:slottable_type, :slottable_id]

  belongs_to :slottable, polymorphic: true

  validates :title, presence: true
end
```

## Privileges

Add `Mission::AVAILABLE_PRIVILEGES` to `FleetRole.all_available_privileges`. Update `FleetRole::DEFAULT_PRIVILEGES`:
- `admin`: all five privileges
- `officer`: read, create, update, delete (no `manage`)
- `member`: read

## API

Routes — extend `config/routes/api/fleets_routes.rb`:

```ruby
resources :fleets, param: :slug do
  resources :missions, param: :slug, only: %i[index show create update destroy] do
    resources :teams, controller: "mission_teams", only: %i[create update destroy]
    resources :ships, controller: "mission_ships", only: %i[create update destroy]
  end
end

# Top-level slot endpoints — polymorphic parent provided in body
resources :mission_slots, path: "mission-slots", only: %i[create update destroy]
```

Five controllers:
- `Api::V1::MissionsController` — index/show/create/update/destroy
- `Api::V1::MissionTeamsController` — create/update/destroy
- `Api::V1::MissionShipsController` — create/update/destroy
- `Api::V1::MissionSlotsController` — create/update/destroy

All use ActionPolicy `authorize!` against the new privileges.

Schema components in `app/api_components/v1/schemas/missions/`:
- `mission.rb` — read schema with embedded teams/ships/slots
- `mission_team.rb`, `mission_ship.rb`, `mission_slot.rb`
- `inputs/mission_create_input.rb`, `mission_update_input.rb`
- `inputs/mission_team_create_input.rb`, `mission_team_update_input.rb`
- `inputs/mission_ship_create_input.rb`, `mission_ship_update_input.rb`
- `inputs/mission_slot_create_input.rb`, `mission_slot_update_input.rb`

Regenerate via `./bin/generate-schema`. Never hand-edit `schema.yaml`.

## Frontend

Pages under `app/frontend/frontend/pages/fleets/[slug]/missions/`:
- `index.vue` — list of missions, "New" button, archived toggle
- `new.vue` — create form (title, description), then redirect to detail
- `[mission-slug].vue` — detail/edit page with three sections: header form, teams list, ships list

Components under `app/frontend/frontend/components/missions/`:
- `MissionForm.vue` — title, description
- `TeamCard.vue` — title, description, slots list, add-slot button
- `ShipCard.vue` — model picker (`ModelSelector`), optional title override, description, slots list
- `SlotForm.vue` — inline form / modal: title, description
- `SlotList.vue` — sortable list of slots with edit/delete

Orval-generated hooks (after schema regeneration): `useFleetMissions`, `useCreateFleetMission`, `useFleetMission`, `useUpdateFleetMission`, `useDestroyFleetMission`, `useCreateMissionTeam`, etc.

State pattern: TanStack Vue Query, mutations invalidate `['fleet', slug, 'missions']` keys.

## i18n

Add to `config/locales/{en,de}/`:
- `resources.yml`: model names, attribute labels
- `messages.yml`: button labels, empty states
- `activerecord.yml`: validation errors

## Tests

- `spec/models/mission_spec.rb`, `mission_team_spec.rb`, `mission_ship_spec.rb`, `mission_slot_spec.rb`
- `spec/requests/api/v1/missions_spec.rb` (and one per nested controller)
- Factories: `spec/factories/missions.rb` etc.
- Skip Playwright system specs for this phase — integration via request specs is sufficient.

## Implementation Order

1. **Migrations + models + privileges** — db schema, model files, FleetRole privilege constants
2. **Model specs + factories** — validate associations, slug generation, lexorank
3. **Policies** — `MissionPolicy`, `MissionTeamPolicy`, `MissionShipPolicy`, `MissionSlotPolicy`
4. **Controllers + routes** — five controllers, request specs
5. **Schema components + `./bin/generate-schema`** then `./bin/format-schema && ./bin/lint-schema`
6. **Frontend Orval regenerate**
7. **Frontend pages + components**
8. **i18n keys**
9. **Manual UI test** — create a mission, add a team with two slots, add a ship with three slots

## Decisions

1. **Slot ordering** — drag-and-drop using the existing `sortablejs` integration (same pattern as `HangarGroupLabels`). Reorder posts `{ sorting: [id, id, ...] }` to a `sort` member action; backend rebalances `rank` via lexorank.
2. **Ship matching** — both strict (`model_id`) and range (filter columns). Resolved to strict at event creation time (future phase).
3. **Delete semantics** — soft delete for missions (`archived_at`); hard delete for teams/ships/slots (they're internal children of the template).
