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

### D8 — Behind a `fleet_squadrons` flag

Every substantial fleet feature on the site is gated — `fleet_allies`,
`fleet_contracts`, `fleet_logistics`, `fleet_mission_builder`, `fleet_tours` —
and this is one. The flag is declared in `config/feature_flags.yml`; the REST
endpoints check it against the fleet actor, and the public ones answer 404
rather than 403 so a flagged-off fleet gives nothing away.

Not in the original plan; added because 5 of 5 comparable features do it.

### D9 — Privileges seed the way the other resources do

The plan gave Admin `fleet:squadrons:manage` outright. The house pattern seeds
`admin: []` and lets `fleet:manage` — which the Admin role already holds — stand
in, because the roles page renders a privilege reached that way as *implied*
rather than as held. Writing it explicitly would say something different about
the role. The effective permissions are exactly what the plan asked for:

- **Admin** — everything, through `fleet:manage`
- **Officer** — `fleet:squadrons:read`, `fleet:squadrons:members:manage`
- **Member** — `fleet:squadrons:read`

`setup_default_roles!` only runs at fleet creation, so a data migration grants
the same set to roles that already exist —
`db/data/20260921120100_grant_squadron_privileges_to_existing_roles.rb`,
following the mission, contract, payout and blueprint backfills before it.

### D10 — Squadron ships and stats subclass, they do not restate

> **Superseded by D12.** These ten endpoints were deleted; a squadron narrows
> the fleet's own pages instead of owning copies of them.

`FleetSquadronVehiclesController < FleetVehiclesController` and
`FleetSquadronStatsController < FleetStatsController`, each overriding a
`vehicle_scope` / `membership_scope` seam. Everything else — the filters, the
grouped-by-model branch, the pagination, the metric arithmetic and the
partials — is identical, and Rails resolves the views through the superclass's
prefix. The same pair exists under `Public::`.

An empty squadron flies nothing: `where(user_id: [])` is what says so, and
dropping the condition for a blank list would hand back the whole fleet.

### D11 — The member count is not cached, the rest of the squadron is

A member *leaving the fleet* is a discard, which leaves the join row in place
and touches nothing on the squadron — so a count inside the cached fragment
would go stale with no way to notice. It is rendered outside the fragment, and
the roster is preloaded so the list still issues a constant number of queries;
`ListEndpointQueryCountsTest` holds that.

### D12 — A squadron is a filter, not a second set of pages

Ten endpoints went, and thirteen test files with them. A squadron is the
fleet's roster sliced, so the slice belongs on the pages that already own the
roster, the ships and the numbers: `q[squadronSlugIn]` narrows the fleet's
member list, ship list, stats, model counts, fleetchart and export.

The alternative was a second ship list and a second stats page carrying the
same filters, the same grouped-by-model branch and the same metric arithmetic
— which is what D10 had planned, and which would have drifted from the
originals the first time either changed.

A squadron's own page keeps only what is its own: the member count, the
description, and three links out to those pages already narrowed to it.

The segmented control that picks one sits above the list rather than in the
filter sidebar, on both the roster and the ship list, and carries an "All"
segment. Single-select, because "All" is meaningless beside a multi-select.

### D13 — Creating a squadron and editing one are the same page

Two tabs — what a squadron is, and what it looks like. Details carries the
name with the team toggle beside it and the two descriptions; Appearance
carries the icon and the colour, the two things every emblem is drawn from.
Tabs are a way of reading one form, not two forms: the fields live in a
composable both layouts share, `keepValuesOnUnmount` keeps the off-screen tab
from dropping what was typed into it, and the submit writes the lot.

The appearance half needs no saved record. The direct-upload endpoint hands back a
signed blob id before anything exists, so a new squadron is written with its
emblem already attached rather than redirecting the author into the editor to
finish the job.

### D14 — A fleet arranges its own squadrons

Alphabetical is not an order anybody chose. `rank` is the default sort and
the association's own order, so the strip on the front page, the filter
segments and the roster badges all follow it rather than only the page it was
arranged on.

A lexorank, the one `FleetRole` already uses. A drag is one squadron moved,
so `PUT …/squadrons/:slug/move` writes that row alone; the unique index on
`(fleet_id, rank)` means two squadrons can never share a place, which a list of
integer positions written whole could not promise once a client sent part of
it. The column is collated "C": the ranks are compared byte by byte, and under
the database's locale collation "g" sorts before "U" and the next rank handed
out repeats one already taken.

Squadrons and teams are one sequence drawn as two rows, so the page counts a
move in the sequence -- after the squadron now ahead of it in its row -- and
not within the row, which would drop it among the other one.

### D15 — Belonging is the rule; `team` marks the exception

Being in two squadrons at once was possible and meant nothing in particular:
the roster badged somebody with whichever of their groups sorted first, and the
member counts added up to more than the fleet had people.

So a member holds at most one squadron in a fleet, and `team` marks the
exception — a standing rota, a trade wing, a crew that cuts across the roster.
A team takes anybody however many they are already on, and being on one never
blocks a squadron: the flag is off on both sides of the rule rather than one.

Refused at the join row, which is what creates the conflict and can therefore
name the squadron standing in the way. Refused again when a team is turned back
into a squadron over members who already have one — nothing would repair a rule
that was already broken when it was turned on, and every later save of an
untouched squadron would then fail on a state somebody else created.

The two are drawn as two rows on the front page, the squadrons page and in
settings. Shown toget### D16 — One picture, an avatar

`icon` only, uploaded and drawn round like a user's avatar. A logo and a header
were built and dropped before the first release: the logo only repeated the
icon on the squadron's own page, and the header was decoration on a page that
since D12 is mostly a member count and three links. Either can come back as an
optional attachment without a migration.

The icon is cropped to its opaque bounds on the way in, so an emblem exported
inside a transparent canvas fills its circle. No transparency is required: a
round crop suits a photograph as well as a cut-out, and the fleet logo and the
user avatar accept either.

hotograph whose edges are the picture,
so it is neither checked nor cropped.

The crop happens in the request where the bytes are already in storage, which
is every direct upload: run behind the request, the response is built from the
padded original and the emblem is drawn inside its transparent canvas until
something reloads the page.

### D17 — Two descriptions

`short_description` is what the card carries and is held to a line or two;
`description` is the squadron's own page and is only serialised by `show`.
Thirty long descriptions would otherwise ride on every grid that renders the
short one.

### D19 — Squadron access is a value in a vocabulary each record already had

An event, a contract and an inventory can be held to squadrons. The switch is
the record's own `visibility` -- "squadron" for an event, `squadron_only` for
an inventory, and for a contract a `visibility` column it never had, at the
value that keeps today's behaviour. Which squadrons is a polymorphic join,
because a record can serve more than one and three columns meaning the same
thing would drift apart.

Both halves are required: a visibility naming no squadron would be visible to
nobody, which is never what anybody meant. Disbanding a squadron releases what
it held, for the same reason.

Enforced twice, because these lists are built by hand rather than through
`authorized_scope`: the scope narrows what is listed and `show?` refuses the
same records one at a time. A list that serves what opening it refuses is the
failure worth catching, so one test runs the same cases over all three.

Whoever runs the fleet's events or contracts still reaches all of them --
including squadron ones they are not in, which they may well have created.

The same rule reaches past the pages. An in-app announcement carries the
title, so a squadron's event or contract is announced to the squadron and to
whoever runs the board, and to nobody else. Discord cannot be narrowed that
way -- the guild and the reminder webhook are the whole fleet -- so a squadron
event is kept off it until a squadron has a channel of its own.

### D18 — Adding and removing are two tasks, not one modal

The picker briefly did both: the squadron's members opened ticked and the
submit wrote the difference. It reads as one control doing two jobs, and the
half that matters most -- seeing who is actually in a squadron -- was buried
in a modal.

So the picker is a picker again, of people not yet in, and the squadron has a
members page: the fleet's roster with the squadron fixed rather than a second
list. Fixed, not filtered -- it is what the page is, not something a reader
can clear. Removal is a row action there, and says plainly that the member
stays in the fleet.

This walks back the part of D12 that left a squadron with no member list. The
rest of D12 stands: the ships and the numbers are still the fleet's own pages
narrowed, because those are lists this feature has nothing to add to. A roster
is different -- it is the one list a squadron *is*.

---

## Progress

- [x] Phase 1 — Database migrations and models
- [x] Phase 2 — Privileges and policies
- [x] Phase 3 — Routes and controllers
- [x] Phase 4 — Jbuilder views and API schema
- [x] Phase 5 — Minitest integration tests
- [x] Phase 6 — Frontend: routes, navigation, pages
- [x] Phase 7 — Frontend: components and settings UI
- [x] Phase 8 — Frontend: member list integration
- [x] Phase 9 — Public fleet squadron views
- [x] Phase 10 — Linting and final schema generation

---

> The phases below are the plan as it was written, and the work followed them
> to a point. Where they and the decision log disagree, the decision log is
> what shipped — D12 in place of the per-squadron endpoints, and D13 in place
> of the create/edit modal of Phase 7. `SquadronModal` and `SquadronBadge` were
> both built and both deleted.

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

**Modify** `config/routes/api/fleets_routes.rb` — there is no per-resource route
file; every nested fleet resource lives in this one, inside the existing
`resources :fleets` block:

```ruby
resources :fleet_squadrons, path: "squadrons", param: :slug, only: %i[index show create update destroy] do
  resources :fleet_squadron_members, path: "members", param: :username, only: %i[index create destroy]

  get "vehicles", to: "fleet_squadron_vehicles#index"
  get "stats/vehicles", to: "fleet_squadron_stats#vehicles"
  get "stats/members", to: "fleet_squadron_stats#members"
end
```

The nested lookup param is `:fleet_squadron_slug`, which is what the member,
vehicle and stats controllers read.

The public half goes in the `namespace :public` block of the same file, with
`only: %i[index show]` and no member routes.

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

Run `./bin/generate-schema` after adding the openapi-ruby specs.

## Phase 5 — Minitest Integration Tests

There is no `spec/` directory: this project is Minitest, and per AGENTS.md API
endpoints get `openapi-ruby` integration tests in `test/integration/`
(`include OpenapiRuby::Adapters::Minitest::DSL`) — the same specs
`bin/generate-schema` reads the OpenAPI document out of. One file per endpoint,
named `fleets_<resource>_<action>_test.rb` after the files already there.

**Create** in `test/integration/api/v1/`:

- `fleets_squadrons_index_test.rb`
- `fleets_squadrons_show_test.rb`
- `fleets_squadrons_create_test.rb`
- `fleets_squadrons_update_test.rb`
- `fleets_squadrons_destroy_test.rb`
- `fleets_squadron_members_index_test.rb`
- `fleets_squadron_members_create_test.rb`
- `fleets_squadron_members_destroy_test.rb`
- `fleets_squadron_vehicles_index_test.rb`
- `fleets_squadron_stats_vehicles_test.rb`
- `fleets_squadron_stats_members_test.rb`
- `fleets_members_squadrons_test.rb` — the badges and the roster filter, which
  ride on the existing members endpoint and so document no path of their own
- `public_fleets_squadrons_index_test.rb`, `public_fleets_squadrons_show_test.rb`,
  `public_fleets_squadron_vehicles_index_test.rb`,
  `public_fleets_squadron_stats_vehicles_test.rb`,
  `public_fleets_squadron_stats_members_test.rb`

**Create** model and policy tests:

- `test/models/fleet_squadron_test.rb`
- `test/models/fleet_squadron_membership_test.rb`
- `test/policies/fleet_squadron_policy_test.rb` — the relation scope and `show?`
  answer alike, which nothing else holds together

**Modify** `test/integration/api/v1/list_endpoint_query_counts_test.rb` — the
squadron list's query count must not grow with the number of squadrons.

**Create** factories:

- `test/factories/fleet_squadrons.rb`
- `test/factories/fleet_squadron_memberships.rb`

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
| `config/routes/api/fleets_routes.rb` | API routes, public half included |
| `config/feature_flags.yml` | The `fleet_squadrons` gate |
| `db/data/…_grant_squadron_privileges_to_existing_roles.rb` | Backfill for roles that already exist |
| `app/lib/versioned_item.rb` | Makes a squadron's paper-trail history readable |
| `app/frontend/frontend/pages/fleets/[slug]/squadrons/` | Frontend pages |
| `app/frontend/frontend/components/Fleets/Squadrons/` | Frontend components |
| `app/frontend/frontend/composables/useFleetNavAccess.ts` | Whether the tab shows |

## Not in Scope (deferred)

- **Squadron ranks** — Asked for during review, to come after this PR: a rank held *within* a squadron, the way a fleet role is held within a fleet. Three to begin with — Squadron Leader, Squadron Officer, Member — shared by every squadron rather than defined per squadron, and later the ability to add roles of a fleet's own on top. Worth settling first: whether a rank carries privileges (who may add or remove members of *this* squadron) or is a label; and whether the three are seeded rows per fleet the way `FleetRole` is, or an enum on the join with custom roles arriving as rows later. `FleetSquadronMembership` is where the rank belongs either way
- ~~**Squadron-scoped contracts and inventories**~~ — Done by D19: a visibility rule, and several squadrons through a polymorphic join
- **Moving a member between squadrons in one step** — D15 makes reassignment two actions, remove and then add. The picker says which squadron holds somebody, and the squadron's members page is where the removal is, but there is no `move`
- **The public front-page strip** — The public endpoints exist, but the strip is gated on membership, so a signed-out visitor to a public fleet sees nothing
- **Squadron chat/messaging** — No in-app messaging system exists yet
- **Squadron events/calendar** — Events can be held to squadrons (D19); a calendar of a squadron's own is still to come
- ~~**Squadron fleetchart**~~ — Done by D12: the fleet's own fleetchart takes `q[squadronSlugIn]` like its other lists
- **Admin squadron management** — Admin panel can manage fleets; squadron admin can be added later
- **Notification types for squadrons** — e.g., `squadron_member_added`; can be added via the notification center once it's complete
- **A Discord channel per squadron** (#5157) — The fleet's guild sync and reminder webhook reach the whole fleet, so an event held to squadrons is kept off both (D19): never posted, and taken down if an edit restricts one that was. Announcing squadron events needs a channel per squadron, on the fleet's own server

## Discovery Log

- **2026-04-22** Initial exec plan
- **2026-09-21** Implementation. Two corrections to the plan as written: there
  is no `spec/` directory (Phase 5 is Minitest in `test/integration/`, which is
  also what generates the OpenAPI document), and nested fleet routes live in
  `config/routes/api/fleets_routes.rb` rather than a file per resource. Four
  decisions the plan had not taken are recorded above as D8–D11: the feature
  flag, how the privileges seed, subclassing for the ship and stat endpoints,
  and keeping the member count out of the cached fragment.
- **2026-09-22** The shape changed twice under review, and the phases above
  describe the first shape rather than the one that shipped. D12 replaces the
  per-squadron endpoints of D10 with a filter dimension, and D13 replaces the
  create/edit modal of Phase 7 with a two-tab page. D14–D17 are the rest of
  what review added: a fleet-chosen order, the squadron/team split, the three
  pictures, and the two descriptions.

- **2026-09-23** Events, contracts and inventories gained squadron access
  (D19), and the member list came back as a page of its own (D18). Two things
  that turned up on the way: `FleetEvent#visibility` has never been enforced
  anywhere -- no policy, controller or scope reads it -- so the squadron value
  is the only one that does anything; and the fleet factory built `fid` from
  three Faker characters, which collides often enough to redden whichever test
  drew second.

  Two bugs the work turned up in code it did not own. `/fleets/:slug/stats/
  vehicles` declared no `q` parameter, so the ship list's metrics and
  classification chips had never followed *any* filter — the squadron filter is
  only what made it visible. And the inline trim of D16 asks every attachment a
  save touched what it is carrying; a purge is one of those changes and carries
  nothing, which broke clearing a picture on nine admin endpoints until it was
  guarded.

- **2026-09-24** The squadron carries one picture instead of three (D16):
  the icon, drawn round, beside the colour on a tab now called Appearance. The
  team toggle moved up beside the name, and the transparency validator went
  with the pictures that needed it.

  Review found D19 enforced on the lists and on `show?` but not on every rule
  that reaches a record by its slug: claiming a contract and reading its crew
  asked the fleet-wide read privilege, and an inventory's manager was listed a
  squadron store its detail refused. The squadron join date became a sort of
  the squadron's own roster only -- across the fleet a member has no single
  answer -- and the public list follows the fleet's order like every other.
