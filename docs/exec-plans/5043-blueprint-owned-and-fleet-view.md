# Mark blueprints as owned, and show a fleet what its members can craft

## Goal

A signed-in reader can mark a crafting recipe as one they hold, filter the
catalogue down to what they hold, and — if they let their fleet see it — have
their org find out who among its members can craft a given thing.

## Context

The blueprints catalogue landed in #5031 as a wholly public read: 1,607 recipes,
what each one makes, what it eats, how good the material has to be, and where it
comes from. Nothing in it is personal. A blueprint in 4.x is an item you acquire,
so "do I have this one" and "does anyone in the org have this one" are the two
questions the catalogue cannot answer today.

The recipe page already reads two user-scoped things — the reader's own material
stock and their fleets' stock, via `useMaterialStock` — so the shape for a
personal panel and a per-fleet fan-out is established rather than new.

Resolves #5043

## Decisions

### D1 — An owned marker, not a quantity

`user_blueprints` holds `user_id`, `blueprint_id` and timestamps, unique on the
pair. No `quantity`, no `charges`.

A blueprint having a limited number of uses is an announced game feature that has
not shipped. Any number modelled now would be invented, and a column that starts
out meaning "1" and later has to mean "uses remaining" is worse than no column.
The table is shaped so that adding one is a plain additive migration: nothing
downstream reads a row as a count, and the payload says `owned: true` rather than
`owned: 1`.

### D2 — One endpoint behind both fleet surfaces

`GET /api/v1/fleets/:slug/blueprints` answers the fleet tab, and the owners panel
on `/blueprints/:slug` asks the same endpoint filtered to one recipe. Two payload
shapes for one question drift; one shape with a filter does not.

The panel therefore fans out one request per fleet the reader belongs to, exactly
as `useMaterialStock` already does for fleet inventory stock, and for the same
reason: the fleets resolve independently, and one fleet answering 403 does not
take the others down with it.

### D3 — Sharing is a per-membership filter, mirroring ships

`fleet_memberships` gains `blueprints_filter`, an enum of `all` / `hide`
defaulting to `all`, editable by the member on their own membership — the same
place, policy and params filter that already carry `ships_filter`.

Rejected: sharing automatically with every fleet you belong to. Ships established
that what a member exposes to an org is the member's call, and a recipe list is
the same kind of disclosure.

Defaulting to `all` rather than `hide`, despite this being a new disclosure
surface: no row exists until the reader marks a recipe themselves, so a member
who never touches the feature shares nothing regardless of the default, and one
who does mark recipes almost certainly did it so their org could see. A default
of `hide` would make the fleet page empty for everybody on day one and read as
broken.

### D4 — A live join, not a `fleet_blueprints` table

`fleet_vehicles` denormalises because a hangar is large, its rows carry
per-vehicle state (loaner, wanted, hangar group) and the filter has a
`hangar_group` mode that has to be re-evaluated per vehicle. None of that is true
here: an owned marker is one row with no state and the filter has two positions,
so the fleet list is

```
Blueprint.where(id: UserBlueprint.where(user_id: <sharing member ids>).select(:blueprint_id))
```

which needs no sync job, no `after_commit` chain and nothing that can fall out of
step. This is the deliberate departure from the ships precedent; everything else
follows it.

### D5 — No feature flag and no subscription gate

Ships with the catalogue, free for every fleet, like the fleet ships page.
Reading is gated by privilege alone.

### D6 — `fleet:blueprints:*` privileges, granted to existing roles

A `FleetBlueprint`-shaped privilege group — `read` / `manage` — registered in
`FleetRole::PRIVILEGE_GROUPS`, defaulting to `read` for members.
`setup_default_roles!` only runs at fleet creation, so a data migration grants
`fleet:blueprints:read` to every existing role, the way
`20260913150000_grant_contract_privileges_to_existing_roles` did for contracts.
Without it every fleet on the site gets a 403 on a tab that looks switched on.

The privilege constant needs a home. There is no `FleetBlueprint` model under D4,
so `AVAILABLE_PRIVILEGES` / `DEFAULT_PRIVILEGES` live on `UserBlueprint` — the
record the fleet is being shown — and `PRIVILEGE_GROUPS` keys it as
`"blueprints"`.

### D7 — The owned flag is rendered outside the fragment cache

`app/views/api/v1/blueprints/_blueprint.jbuilder` wraps the whole payload in
`json.cache!` keyed on the blueprint, its build and the current source — no user
anywhere in the key. `owned` emitted inside that block would serve the first
reader's answer to every subsequent one. It goes after the `cache!` block, in the
same partial, where it is computed per request.

### D8 — The owned filter is applied by the controller, not through ransack

Same trap `with_known_source` documents at length in `Blueprint`: ransack casts a
scope argument to a boolean and then skips the scope when it is false, so
`owned=false` would return the whole catalogue rather than the recipes the reader
does not hold. The controller reads the flag off the permitted query params and
applies the scope itself.

## What changed

### Phase 1 — The owned marker

1. Migration `create_user_blueprints`: `user_id`, `blueprint_id`, timestamps,
   unique index on the pair, FKs cascading on delete.
2. `UserBlueprint` model; `has_many :user_blueprints` / `has_many :blueprints,
   through:` on `User`; `has_many :user_blueprints, dependent: :destroy` on
   `Blueprint`.
3. `Blueprint.owned_by(user)` and `.not_owned_by(user)` scopes, written as exists
   checks like every other scope on that model.
4. `POST /blueprints/:slug/own` and `DELETE /blueprints/:slug/own` on the
   existing blueprints resource; `BlueprintPolicy` for the two new actions,
   authenticated only.
5. `owned` on the blueprint payload, outside the cache block (D7), false when
   signed out. The index preloads the reader's owned ids for the page in one
   query rather than asking per row.
6. `ownedEq` in `BlueprintQuery`, applied by the controller (D8).
7. Integration tests in `test/integration/` for own/unown/filter, factory for
   `UserBlueprint`, model test for the scopes.

### Phase 2 — Reaching the fleet

1. Migration adding `blueprints_filter` (integer, default 0) to
   `fleet_memberships`; enum `{all: 0, hide: 1}`, prefixed, defaulted in
   `set_default_blueprints_filter` beside the ships one.
2. `blueprints_filter` into `FleetMembershipPolicy`'s params filter and into
   `FleetMembershipUpdateInput`; a `FleetMembershipBlueprintsFilterEnum`
   component sourced from the model.
3. `UserBlueprint::AVAILABLE_PRIVILEGES` / `DEFAULT_PRIVILEGES`, registered in
   `FleetRole::PRIVILEGE_GROUPS` and `preset_privileges` (D6).
4. Data migration granting `fleet:blueprints:read` to existing roles, and
   `fleet:blueprints:manage` to anyone who already manages the fleet or its
   memberships.
5. `GET /fleets/:slug/blueprints` → `Api::V1::FleetBlueprintsController`, with
   `FleetBlueprintPolicy`, the sharing-member subquery (D4), the catalogue's own
   ransack surface, and `owners` + `ownerCount` per row.
6. `FleetBlueprint` / `FleetBlueprints` / `FleetBlueprintOwner` components and a
   `FleetBlueprintQuery`; integration tests covering the privilege gate, the
   `hide` filter, and the single-recipe filter the panel uses.
7. Membership capabilities: `readBlueprints` alongside `readInventories` on the
   membership payload, so the nav can ask one flag.

### Phase 3 — The catalogue, in the browser

1. `BlueprintOwnToggle` — a bookmark-style `Btn` calling the own/unown mutations
   and invalidating the blueprint queries; on the detail page's masthead and on
   `BlueprintRow`. Signed out it prompts to sign in rather than rendering absent,
   the way `AddToHangar` does.
2. An `owned` three-state select in `Blueprints/FilterForm`, carrying strings
   rather than booleans for the reason the `withKnownSource` select documents.
3. `owned` into `useBlueprintFilters`' prefill.
4. Translations in all seven locales.

### Phase 4 — The fleet, in the browser

1. `/fleets/:slug/blueprints` route + page, built on `FilteredList` like the
   catalogue, with an owners column.
2. `showBlueprintsNav` in `useFleetNavAccess`, a nav item in `FleetNav` and in
   the mobile nav, and the `prefix` numbering resequenced around it.
3. The owners panel on `/blueprints/:slug`: a `useBlueprintFleetOwners`
   composable fanning out over `useMyFleets` with `useQueries`, modelled on
   `useMaterialStock`.
4. `blueprintsFilter` select on the membership settings page.
5. `privilegeGroups.blueprints` and the four privilege labels, in all seven
   locales — the thing #5031-era features have repeatedly shipped missing.
6. Fleet-scoped blueprint queries into `clearSession`'s cache purge: the panel is
   user-scoped on a public page, which is exactly the leak the hangar stock purge
   there exists to prevent.

### Phase 5 — Closing

1. `bundle exec standardrb --fix`, `pnpm lint:fix`, `pnpm lint:ts`.
2. `./bin/generate-schema` then `pnpm orval` — the server has to be restarted
   first or new params 400 during generation.
3. `bin/rails test` on the touched files, `pnpm test` on the touched specs.

## Intent Verification

- [ ] **Mark and unmark** — a signed-in reader toggles ownership from the recipe
      page and from a catalogue row, and it survives a reload
- [ ] **Own filter** — `?owned=true` narrows the catalogue to held recipes and
      `?owned=false` to the rest, neither returning all 1,607
- [ ] **Anonymous unchanged** — a signed-out read of the catalogue and of a
      recipe is byte-identical to today apart from `owned: false`
- [ ] **Fleet list** — `/fleets/:slug/blueprints` lists what members hold, with
      who holds each, paginated and sortable
- [ ] **Owners panel** — the recipe page names the members of each of the
      reader's fleets who hold it
- [ ] **Hiding works** — a member setting `blueprintsFilter` to `hide` disappears
      from both fleet surfaces
- [ ] **Privilege gate** — a role without `fleet:blueprints:read` gets no tab and
      a 403 from the endpoint; every pre-existing role has the privilege after
      the data migration
- [ ] **No cache bleed** — two readers of the same recipe get their own `owned`
- [ ] **Schema** — `./bin/generate-schema` is clean and the Orval clients carry
      the new operations

## Key files

| File | Role |
|------|------|
| `app/models/blueprint.rb` | Scopes, ransack surface, the filter traps documented in place |
| `app/models/user_blueprint.rb` | New: the marker, and the fleet privilege constants (D6) |
| `app/models/fleet_membership.rb` | `blueprints_filter` beside `ships_filter` |
| `app/models/fleet_role.rb` | `PRIVILEGE_GROUPS`, `preset_privileges` |
| `app/controllers/api/v1/blueprints_controller.rb` | `own` / `unown`, the owned filter |
| `app/controllers/api/v1/fleet_blueprints_controller.rb` | New: the fleet list |
| `app/views/api/v1/blueprints/_blueprint.jbuilder` | The fragment cache `owned` must sit outside (D7) |
| `app/policies/fleet_membership_policy.rb` | Params filter for the new setting |
| `db/data/…_grant_blueprint_privileges_to_existing_roles.rb` | New: D6's backfill |
| `app/frontend/frontend/composables/useMaterialStock.ts` | The fan-out the owners panel copies |
| `app/frontend/frontend/composables/useFleetNavAccess.ts` | Where the new tab's visibility is decided |
| `app/frontend/frontend/stores/session.ts` | The purge a user-scoped query on a public page must join |

## Not in scope (deferred)

- **Uses / charges per blueprint** — an announced game feature that has not
  shipped (D1)
- **A fleet-owned blueprint library** — recipes belonging to the org rather than
  to its members
- **Crafting assignments** — "who is making this" on top of "who can make it"
- **A public `/hangar/:username/blueprints`** — the fleet is the only audience
  asked for

## Discovery Log

- **2026-09-19** Research and plan. Confirmed: the blueprint payload is fragment
  cached with no user in the key (D7); ransack skips false-valued scopes, already
  documented on `Blueprint` for `with_known_source` (D8); `FleetRole` presets only
  run at fleet creation, so a grant migration is required (D6);
  `FleetRoleResourceAccessEnum` sources from `FleetRole.all_available_privileges`,
  so the API enum follows the model without a schema edit.

## Progress

- [ ] Phase 1 — The owned marker
- [ ] Phase 2 — Reaching the fleet
- [ ] Phase 3 — The catalogue, in the browser
- [ ] Phase 4 — The fleet, in the browser
- [ ] Phase 5 — Closing
