# Fleet Squadrons

Squadrons add a sub-group layer within fleets, allowing fleet admins and officers to organize members into named groups (e.g., combat wing, mining division, logistics team). Each squadron is a named group of fleet members within a single fleet. A fleet member can belong to multiple squadrons. Squadrons inherit the fleet's role-based privilege system — no separate squadron roles. Vehicle and stats views can be filtered per squadron.

Resolves [#1398](https://github.com/fleetyards/fleetyards/issues/1398).

## Current State

Fleets have a flat member structure: every accepted `FleetMembership` belongs directly to the fleet. The only organizational axis is the `FleetRole` (Admin / Officer / Member). There is no way to group members into sub-units for operational organization, filtered vehicle views, or squadron-level stats.

## Data Model

### FleetSquadron

New model representing a named group within a fleet.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | uuid | PK |
| `fleet_id` | uuid | FK → fleets, NOT NULL |
| `name` | string | NOT NULL, unique (case-insensitive, scoped to fleet) |
| `slug` | string | NOT NULL, unique (scoped to fleet), auto-generated |
| `description` | text | nullable |
| `logo` | ActiveStorage | optional |
| `color` | string | nullable, hex color for UI badge |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Indexes:
- `(fleet_id, slug)` unique
- `(fleet_id, name)` unique (case-insensitive)

### FleetSquadronMembership

Join table linking fleet members to squadrons.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | uuid | PK |
| `fleet_squadron_id` | uuid | FK → fleet_squadrons, NOT NULL |
| `fleet_membership_id` | uuid | FK → fleet_memberships, NOT NULL |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Indexes:
- `(fleet_squadron_id, fleet_membership_id)` unique

## Associations

```
Fleet
  has_many :fleet_squadrons, dependent: :destroy

FleetSquadron
  belongs_to :fleet
  has_many :fleet_squadron_memberships, dependent: :destroy
  has_many :fleet_memberships, through: :fleet_squadron_memberships
  has_many :users, through: :fleet_memberships
  has_one_attached :logo

FleetSquadronMembership
  belongs_to :fleet_squadron
  belongs_to :fleet_membership

FleetMembership (existing, modified)
  has_many :fleet_squadron_memberships, dependent: :destroy
  has_many :fleet_squadrons, through: :fleet_squadron_memberships
```

## Privileges

Extend the existing fleet privilege system with a new `squadrons` resource. Added to `FleetSquadron::AVAILABLE_PRIVILEGES`:

| Privilege | Description |
|-----------|-------------|
| `fleet:squadrons:read` | View squadrons and their members |
| `fleet:squadrons:create` | Create new squadrons |
| `fleet:squadrons:update` | Edit squadron name/description/logo/color |
| `fleet:squadrons:delete` | Delete squadrons |
| `fleet:squadrons:manage` | Full squadron management (superset) |
| `fleet:squadrons:members:manage` | Add/remove members from squadrons |

Default role privileges:
- **Admin**: `fleet:squadrons:manage` (includes all)
- **Officer**: `fleet:squadrons:read`, `fleet:squadrons:members:manage`
- **Member**: `fleet:squadrons:read`

## API Endpoints

All nested under `/api/v1/fleets/:fleet_slug/`.

### Squadrons CRUD

| Method | Path | Action | Auth |
|--------|------|--------|------|
| `GET` | `squadrons` | List squadrons | `squadrons:read` |
| `GET` | `squadrons/:slug` | Show squadron detail | `squadrons:read` |
| `POST` | `squadrons` | Create squadron | `squadrons:create` |
| `PUT` | `squadrons/:slug` | Update squadron | `squadrons:update` |
| `DELETE` | `squadrons/:slug` | Delete squadron | `squadrons:delete` |

### Squadron Members

| Method | Path | Action | Auth |
|--------|------|--------|------|
| `GET` | `squadrons/:slug/members` | List squadron members | `squadrons:read` |
| `POST` | `squadrons/:slug/members` | Add member to squadron | `squadrons:members:manage` |
| `DELETE` | `squadrons/:slug/members/:username` | Remove member from squadron | `squadrons:members:manage` |

### Squadron Vehicles & Stats

| Method | Path | Action | Auth |
|--------|------|--------|------|
| `GET` | `squadrons/:slug/vehicles` | List squadron member vehicles | `squadrons:read` + `vehicles:read` |
| `GET` | `squadrons/:slug/stats/vehicles` | Squadron vehicle stats | `squadrons:read` + `vehicles:read` |
| `GET` | `squadrons/:slug/stats/members` | Squadron member stats | `squadrons:read` |

## Frontend

### Navigation

Add a "Squadrons" tab to the fleet detail nav (between Members and Stats):

```
Overview | Ships | Members | Squadrons | Stats | Settings
```

### Pages

| Route | Page | Description |
|-------|------|-------------|
| `/fleets/:slug/squadrons` | `fleets/[slug]/squadrons/index.vue` | Squadron list with cards showing name, color, logo, member count |
| `/fleets/:slug/squadrons/:squadron` | `fleets/[slug]/squadrons/[squadron].vue` | Squadron detail — members list, vehicles, stats |

### Settings

Add a "Squadrons" section to fleet settings (only visible with `squadrons:create` or `squadrons:manage`):
- Create/edit/delete squadrons
- Assign/remove members via a member picker modal

### Components

| Component | Purpose |
|-----------|---------|
| `Fleets/SquadronCard/index.vue` | Card displaying squadron name, color badge, logo, member count |
| `Fleets/SquadronModal/index.vue` | Create/edit squadron form (name, description, color, logo) |
| `Fleets/SquadronMemberPicker/index.vue` | Modal to add fleet members to a squadron |
| `Fleets/SquadronBadge/index.vue` | Small colored badge with squadron name (used in member lists) |

### Member List Integration

On the existing fleet members list (`/fleets/:slug/members`), add:
- A squadron badge next to each member showing their squadron(s)
- A filter option to filter members by squadron

### Public Fleet

If the fleet is public, squadron list and squadron vehicle views are also visible on the public fleet page. No member details are exposed publicly (same as current behavior).

## Decisions

### D1 — No separate squadron roles

Squadrons inherit the fleet's role-based permission system. A squadron does not have its own admin/officer/member hierarchy. Fleet-level roles determine who can manage squadrons. This avoids complexity and role confusion.

### D2 — Many-to-many membership

A fleet member can belong to multiple squadrons. This mirrors real-world org structures where someone might be in both a combat wing and a logistics team.

### D3 — Squadron vehicles are derived

No separate `fleet_squadron_vehicles` table. Squadron vehicles are the fleet vehicles belonging to squadron members. This avoids data duplication and sync issues.

### D4 — Slug-based routing

Squadrons use slugs (auto-generated from name, scoped to fleet) for URL-friendly routing, consistent with how fleets themselves work.

### D5 — Color for UI differentiation

A hex color field allows visual differentiation of squadrons in the UI (badges, cards). Optional — defaults to a neutral color if not set.

### D6 — Cascading deletes

When a squadron is deleted, its memberships are destroyed but the underlying fleet memberships remain untouched. When a fleet membership is destroyed (member leaves fleet), their squadron memberships are also destroyed.

### D7 — Public squadrons

Public fleets expose squadron list and squadron vehicle stats. Squadron member identities are not exposed publicly, consistent with existing public fleet behavior where member counts are shown but usernames are not.

---

## Progress

- [ ] Phase 1 — Database migrations and models
- [ ] Phase 2 — Privileges and policies
- [ ] Phase 3 — Routes and controllers
- [ ] Phase 4 — Jbuilder views and API schema
- [ ] Phase 5 — RSpec request specs
- [ ] Phase 6 — Frontend: routes, navigation, pages
- [ ] Phase 7 — Frontend: components and settings UI
- [ ] Phase 8 — Frontend: member list integration
- [ ] Phase 9 — Public fleet squadron views
- [ ] Phase 10 — Linting and final schema generation

---

## Phase 1 — Database Migrations and Models

### Migration 1: Create fleet_squadrons

```ruby
create_table :fleet_squadrons, id: :uuid do |t|
  t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
  t.string :name, null: false
  t.string :slug, null: false
  t.text :description
  t.string :color
  t.timestamps
end

add_index :fleet_squadrons, [:fleet_id, :slug], unique: true
add_index :fleet_squadrons, "fleet_id, LOWER(name)", unique: true, name: "index_fleet_squadrons_on_fleet_id_and_lower_name"
```

### Migration 2: Create fleet_squadron_memberships

```ruby
create_table :fleet_squadron_memberships, id: :uuid do |t|
  t.references :fleet_squadron, type: :uuid, null: false, foreign_key: true
  t.references :fleet_membership, type: :uuid, null: false, foreign_key: true
  t.timestamps
end

add_index :fleet_squadron_memberships, [:fleet_squadron_id, :fleet_membership_id],
  unique: true, name: "idx_squadron_memberships_unique"
```

### Models

**Create** `app/models/fleet_squadron.rb`

- `belongs_to :fleet`
- `has_many :fleet_squadron_memberships, dependent: :destroy`
- `has_many :fleet_memberships, through: :fleet_squadron_memberships`
- `has_many :users, through: :fleet_memberships`
- `has_one_attached :logo`
- Validations: name presence, uniqueness (case-insensitive scoped to fleet_id), format
- Slug generation via `before_validation` (similar to Fleet)
- Pagination: 30 per page
- `AVAILABLE_PRIVILEGES` constant

**Create** `app/models/fleet_squadron_membership.rb`

- `belongs_to :fleet_squadron`
- `belongs_to :fleet_membership`
- Validation: uniqueness of fleet_membership scoped to fleet_squadron
- Validate fleet_membership belongs to same fleet as fleet_squadron

**Modify** `app/models/fleet.rb`

- Add `has_many :fleet_squadrons, dependent: :destroy`

**Modify** `app/models/fleet_membership.rb`

- Add `has_many :fleet_squadron_memberships, dependent: :destroy`
- Add `has_many :fleet_squadrons, through: :fleet_squadron_memberships`

## Phase 2 — Privileges and Policies

### Modify `app/models/fleet_squadron.rb`

Add `AVAILABLE_PRIVILEGES`:

```ruby
AVAILABLE_PRIVILEGES = {
  admin: %w[fleet:squadrons:manage],
  officer: %w[fleet:squadrons:read fleet:squadrons:members:manage],
  member: %w[fleet:squadrons:read]
}.freeze
```

### Modify `app/models/fleet_role.rb`

Add `FleetSquadron` to `all_available_privileges` and `preset_privileges`.

### Create `app/policies/fleet_squadron_policy.rb`

- Inherit from `FleetBasePolicy` (same pattern as other fleet policies)
- `index?` — requires `fleet:squadrons:read` or `fleet:squadrons:manage`
- `show?` — requires `fleet:squadrons:read` or `fleet:squadrons:manage`
- `create?` — requires `fleet:squadrons:create` or `fleet:squadrons:manage`
- `update?` — requires `fleet:squadrons:update` or `fleet:squadrons:manage`
- `destroy?` — requires `fleet:squadrons:delete` or `fleet:squadrons:manage`

### Create `app/policies/fleet_squadron_membership_policy.rb`

- `index?` — requires `fleet:squadrons:read`
- `create?` — requires `fleet:squadrons:members:manage` or `fleet:squadrons:manage`
- `destroy?` — requires `fleet:squadrons:members:manage` or `fleet:squadrons:manage`

## Phase 3 — Routes and Controllers

### Routes

**Create** `config/routes/api/fleet_squadrons_routes.rb`

Nested under the existing fleet resource:

```ruby
resources :squadrons, param: :slug, controller: "fleet_squadrons" do
  resources :members, controller: "fleet_squadron_members", only: [:index, :create, :destroy], param: :username
  get "vehicles", to: "fleet_squadron_vehicles#index"
  get "stats/vehicles", to: "fleet_squadron_stats#vehicles"
  get "stats/members", to: "fleet_squadron_stats#members"
end
```

### Controllers

**Create** `app/controllers/api/v1/fleet_squadrons_controller.rb`

- Standard CRUD: index, show, create, update, destroy
- Params: `name`, `description`, `color`, `logo`, `remove_logo`
- Fleet lookup via `fleet_slug`

**Create** `app/controllers/api/v1/fleet_squadron_members_controller.rb`

- `index` — list squadron members (with pagination, same filters as fleet members)
- `create` — add fleet member to squadron by username
- `destroy` — remove member from squadron by username

**Create** `app/controllers/api/v1/fleet_squadron_vehicles_controller.rb`

- `index` — list vehicles belonging to squadron members (reuse `FleetVehicleFiltersConcern`)

**Create** `app/controllers/api/v1/fleet_squadron_stats_controller.rb`

- `vehicles` — vehicle stats for squadron members
- `members` — member count stats for squadron

## Phase 4 — Jbuilder Views and API Schema

### Views

**Create** `app/views/api/v1/fleet_squadrons/`

- `_base.jbuilder` — id, name, slug, description, color, logo_url, member_count, created_at, updated_at
- `_fleet_squadron.jbuilder` — partial wrapper
- `index.jbuilder` — array
- `show.jbuilder` — single

**Create** `app/views/api/v1/fleet_squadron_members/`

- Reuse existing fleet member view partials

**Create** `app/views/api/v1/fleet_squadron_vehicles/`

- Reuse existing fleet vehicle view partials

### API Schema Components

**Create** `app/api_components/v1/schemas/fleet_squadron.rb`

**Update** `app/api_components/v1/schemas/fleet_membership.rb` — add `squadrons` array to membership response

### Generate schema

Run `./bin/generate-schema` after adding rswag specs.

## Phase 5 — RSpec Request Specs

**Create** specs in `spec/requests/api/v1/`:

- `fleet_squadrons/index_spec.rb`
- `fleet_squadrons/show_spec.rb`
- `fleet_squadrons/create_spec.rb`
- `fleet_squadrons/update_spec.rb`
- `fleet_squadrons/destroy_spec.rb`
- `fleet_squadron_members/index_spec.rb`
- `fleet_squadron_members/create_spec.rb`
- `fleet_squadron_members/destroy_spec.rb`
- `fleet_squadron_vehicles/index_spec.rb`
- `fleet_squadron_stats/vehicles_spec.rb`
- `fleet_squadron_stats/members_spec.rb`

**Create** factories:

- `spec/factories/fleet_squadrons.rb`
- `spec/factories/fleet_squadron_memberships.rb`

## Phase 6 — Frontend: Routes, Navigation, Pages

### Routes

**Modify** `app/frontend/frontend/pages/fleets/[slug]/routes.ts`

Add squadron routes:

```ts
{
  path: "squadrons",
  name: "fleet-squadrons",
  component: () => import("./squadrons/index.vue"),
  children: [
    {
      path: ":squadron",
      name: "fleet-squadron",
      component: () => import("./squadrons/[squadron].vue"),
    },
  ],
}
```

### Navigation

**Modify** `app/frontend/frontend/components/Navigation/FleetNav/index.vue`

Add "Squadrons" tab between Members and Stats.

### Pages

**Create** `app/frontend/frontend/pages/fleets/[slug]/squadrons/index.vue`

- Grid of SquadronCard components
- Create button (if user has `squadrons:create`)

**Create** `app/frontend/frontend/pages/fleets/[slug]/squadrons/[squadron].vue`

- Squadron detail page with tabs: Members, Ships, Stats
- Edit/delete controls (if user has `squadrons:update`/`squadrons:delete`)

### Translations

Add squadron-related keys to all language files:
- `labels.json` — squadron, squadrons
- `nav.json` — squadrons navigation
- `headlines.json` — squadron headings
- `actions.json` — create/edit/delete squadron actions
- `messages.json` — squadron creation/deletion messages

## Phase 7 — Frontend: Components and Settings UI

### Components

**Create** `app/frontend/frontend/components/Fleets/SquadronCard/index.vue`

- Displays squadron logo (or color swatch), name, member count
- Click navigates to squadron detail

**Create** `app/frontend/frontend/components/Fleets/SquadronModal/index.vue`

- Form: name, description, color picker, logo upload
- Used for both create and edit

**Create** `app/frontend/frontend/components/Fleets/SquadronMemberPicker/index.vue`

- Modal listing fleet members not yet in the squadron
- Search/filter by username
- Checkbox selection + add button

**Create** `app/frontend/frontend/components/Fleets/SquadronBadge/index.vue`

- Small badge with squadron color and name
- Used in member lists and detail views

### Settings

**Modify** `app/frontend/frontend/pages/fleets/[slug]/settings.vue`

Add "Squadrons" settings tab (visible with `squadrons:manage` or `squadrons:create`):
- List of squadrons with edit/delete actions
- Create new squadron button

## Phase 8 — Frontend: Member List Integration

**Modify** `app/frontend/frontend/components/Fleets/MembersList/index.vue`

- Display squadron badges next to each member
- Add squadron filter dropdown to the members filter form

**Modify** `app/frontend/frontend/components/Fleets/MembersFilterForm/index.vue`

- Add squadron multi-select filter

**Modify** Orval config to regenerate API client after schema changes.

## Phase 9 — Public Fleet Squadron Views

**Create** `app/controllers/api/v1/public/fleet_squadrons_controller.rb`

- `index` — list squadrons (name, color, logo, member count only)
- `show` — squadron detail (no member usernames)

**Create** `app/controllers/api/v1/public/fleet_squadron_vehicles_controller.rb`

- `index` — squadron vehicles for public fleets

**Create** `app/controllers/api/v1/public/fleet_squadron_stats_controller.rb`

- Vehicle and member stats for public squadrons

**Add routes** to `config/routes/api/public_routes.rb` or equivalent.

**Create** corresponding views and policies.

## Phase 10 — Linting and Final Schema Generation

1. `bundle exec standardrb --fix` on all new/modified `.rb` files
2. `pnpm lint:fix` on all new/modified frontend files
3. `./bin/generate-schema` to regenerate OpenAPI schema
4. Run full test suite: `rspec` and `pnpm test`

## Key Files

| File | Role |
|------|------|
| `app/models/fleet_squadron.rb` | Squadron model |
| `app/models/fleet_squadron_membership.rb` | Squadron ↔ Member join |
| `app/models/fleet.rb` | Add squadron association |
| `app/models/fleet_membership.rb` | Add squadron association |
| `app/models/fleet_role.rb` | Add squadron privileges |
| `app/controllers/api/v1/fleet_squadrons_controller.rb` | Squadron CRUD |
| `app/controllers/api/v1/fleet_squadron_members_controller.rb` | Squadron member management |
| `app/controllers/api/v1/fleet_squadron_vehicles_controller.rb` | Squadron vehicles |
| `app/controllers/api/v1/fleet_squadron_stats_controller.rb` | Squadron stats |
| `app/policies/fleet_squadron_policy.rb` | Squadron authorization |
| `app/policies/fleet_squadron_membership_policy.rb` | Squadron member authorization |
| `config/routes/api/fleet_squadrons_routes.rb` | API routes |
| `app/frontend/frontend/pages/fleets/[slug]/squadrons/` | Frontend pages |
| `app/frontend/frontend/components/Fleets/Squadron*/` | Frontend components |

## Not in Scope (deferred)

- **Squadron-level roles** — Squadrons inherit fleet roles; a separate squadron role hierarchy could be added later if needed
- **Squadron chat/messaging** — No in-app messaging system exists yet
- **Squadron events/calendar** — Future feature
- **Squadron fleetchart** — Could reuse existing fleetchart filtered by squadron; deferred to avoid scope creep
- **Admin squadron management** — Admin panel can manage fleets; squadron admin can be added later
- **Notification types for squadrons** — e.g., `squadron_member_added`; can be added via the notification center once it's complete

## Discovery Log

- **2026-04-22** Initial exec plan
