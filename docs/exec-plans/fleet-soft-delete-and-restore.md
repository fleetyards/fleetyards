# Exec Plan: Fleet Soft-Delete, Whodunnit & Admin Restore

## Problem

A fleet was hard-destroyed and there is currently no way to:

1. Recover it (the record only survives as PaperTrail `destroy` versions).
2. Tell **who** destroyed it — whodunnit is unrecorded for fleet operations.
3. Prevent the same data loss in future — fleet/membership deletion is a permanent `destroy` with `dependent: :destroy` cascade.

## Current State

- `paper_trail` 17.0.0 is present; `discard` is **not**. No soft-delete gem anywhere (one model, `ModelHardpoint`, hand-rolls `deleted_at` + scopes).
- `Fleet` and `FleetMembership` both `has_paper_trail meta: { author_id:, reason:, reason_description: }`, but those `attr_accessor`s are **never assigned anywhere** — the custom meta is dead, those version columns are always nil.
- `set_paper_trail_whodunnit` runs only in `Admin::ApplicationController` (the server-rendered admin). Neither `Api::BaseController` nor `Admin::Api::BaseController` set whodunnit, so **API/admin-API destroys record nil whodunnit**.
- `versions.object` column is **`json`** → PaperTrail stores attribute snapshots as a JSON hash; we can query `object ->> 'fid'` / `object ->> 'name'` in SQL.
- Deletion is hard `destroy` in `Api::V1::FleetsController#destroy`, `Admin::Api::V1::FleetsController#destroy`, `Api::V1::FleetMembershipsController#destroy`. `Fleet` cascades `dependent: :destroy` to roles, memberships, invite_urls, inventories, vehicles.
- `Fleet` runs `after_create :setup_default_roles!` and `after_create :setup_admin_user` (the latter creates a membership for `created_by`).
- Unique indexes: `fleets(fid)` unique; `fleet_memberships(user_id, fleet_id)` unique; `fleet_roles(fleet_id, rank)` unique.
- Admin UI: Vue 3 SPA at `app/frontend/admin`, routes+meta-driven nav, Orval-generated TanStack Query hooks against `swagger/admin/v1/schema.yaml`, jbuilder responses, ActionPolicy authorization, Ransack + Kaminari. Schema is generated from integration tests via `./bin/generate-schema`, never edited by hand.

## Decisions (confirmed with user)

1. **Recover the current fleet through the new admin page**, not a throwaway rake task/console script. → the page must support legacy hard-deletes.
2. **Admin page restores from BOTH sources**: discarded records (future) + PaperTrail `destroy` versions (legacy hard-deletes).
3. **Explicit `kept` scope** — no `default_scope`. Existing queries stay as-is; we add `.kept` only where lists must hide discarded fleets.

### Fidelity note (drives the UI)

- **Discarded restores are high-fidelity**: roles, invite_urls, inventories, fleet_vehicles, and ActiveStorage attachments all stay in the DB (discard is a column flip, the `dependent: :destroy` cascade does *not* fire). `undiscard` brings everything back intact.
- **PaperTrail (purged) restores are best-effort**. After this plan, the versioned set is: `Fleet`, `FleetMembership`, `FleetRole`, `FleetInventory`, `FleetInventoryItem`. So a purged restore can rebuild the fleet, its roles, memberships, inventories, and inventory items. **Not recoverable** on a purged restore: ActiveStorage attachments (`logo`, `background_image`, inventory/item `image`), `fleet_invite_urls`, and `fleet_vehicles` (the latter regenerate from members' hangars after restore). The UI must warn about this on the purged tab.

### Why these relations (and not the others)

| Relation | Versioned? | Reason |
|---|---|---|
| `fleet_memberships` | ✅ (already) | user data, needed for restore |
| `fleet_roles` | ✅ add | low churn; enables membership `fleet_role_id` remap by name |
| `fleet_inventories` | ✅ add | member-authored content |
| `fleet_inventory_items` | ✅ add | the actual inventory contents |
| `fleet_invite_urls` | ❌ skip | ephemeral tokens; `usage_count` churns versions; low restore value |
| `fleet_vehicles` | ❌ skip | auto-derived from member hangars (`FleetMembershipVehiclesSetupJob`); regenerate on restore; very high churn |

## Plan

### Phase 1 — Add `discard` gem
**Commit:** `chore(deps): add discard gem`
- Add `gem "discard", "~> 1.3"` to `Gemfile`, `bundle install`.

### Phase 2 — Migration: discard columns + partial unique indexes
**Commit:** `feat(fleets): add discarded_at to fleets and fleet_memberships`
- `add_column :fleets, :discarded_at, :datetime` + `add_index :fleets, :discarded_at`.
- `add_column :fleet_memberships, :discarded_at, :datetime` + index.
- Replace the unique indexes with partial ones so discarded rows don't block re-creation/restore:
  - drop `index_fleets_on_fid`; re-add `unique, where: "discarded_at IS NULL"`.
  - drop `index_fleet_memberships_on_user_id_and_fleet_id`; re-add `unique, where: "discarded_at IS NULL"`.
- Leave `fleet_roles(fleet_id, rank)` untouched (roles aren't discarded).

### Phase 3 — Soft-delete in the models
**Commit:** `feat(fleets): soft-delete Fleet and FleetMembership via discard`
- `Fleet`: `include Discard::Model` (no `default_scope`).
  - `after_discard { fleet_memberships.kept.find_each(&:discard) }`
  - `after_undiscard { fleet_memberships.discarded.find_each(&:undiscard) }`
  - Keep `dependent: :destroy` for genuine hard purges (admin-only, later), but the default path becomes discard.
- `FleetMembership`: `include Discard::Model`.
  - Audit `before_destroy :check_if_can_be_destroyed` and `after_destroy` hooks (`broadcast_destroy`, `remove_fleet_vehicles`): discard does **not** fire `destroy` callbacks, so add `after_discard`/`after_undiscard` equivalents where the side effects matter (e.g. broadcast, fleet_vehicle recompute). Verify each callback's intent before wiring.

### Phase 3b — Version restorable fleet relations
**Commit:** `feat(fleets): track paper_trail on roles and inventories`
- Add `has_paper_trail` to `FleetRole`, `FleetInventory`, `FleetInventoryItem`.
- These are not discarded (no `discarded_at`); they survive a fleet *discard* untouched (the `dependent: :destroy` cascade only fires on hard `destroy`). Versioning them exists purely for **purged** (legacy hard-delete) restore fidelity.
- Match the existing meta convention or keep it minimal — whodunnit (Phase 4) is the source of truth for "who".

### Phase 4 — Record whodunnit on API + admin-API
**Commit:** `feat(api): record paper_trail whodunnit for API requests`
- `Api::BaseController`: `before_action { PaperTrail.request.whodunnit = current_resource_owner&.id }`.
- `Admin::Api::BaseController`: `before_action { PaperTrail.request.whodunnit = current_admin_user&.id }`.
- This populates the `whodunnit` column for **every** versioned model going forward, including the discard (an `update` event setting `discarded_at`) — so "who destroyed a fleet" is finally captured.
- Also set the custom `author_id` accessor in the fleet/membership discard paths (cheap, keeps the existing custom column meaningful). The dead `author_id`/`update_reason` meta otherwise stays nil; document that whodunnit is the source of truth.

### Phase 5 — Switch destroy actions to discard
**Commit:** `refactor(fleets): soft-delete instead of hard destroy`
- `Api::V1::FleetsController#destroy` → `@fleet.discard`.
- `Admin::Api::V1::FleetsController#destroy` → `@fleet.discard`.
- `Api::V1::FleetMembershipsController#destroy` → `@membership.discard`.
- Add `.kept` to the member-facing fleet/membership listing queries so discarded fleets disappear from normal views (audit: `Fleet.all` in controllers, "my fleets", public fleet lists, fleet lookups by slug/fid). Admin index keeps showing all (or `kept`, TBD — admins manage via the new page).

### Phase 6 — Admin "Destroyed Fleets" API (both sources)
**Commit:** `feat(admin): destroyed fleets restore endpoints`
- New `Admin::Api::V1::DestroyedFleetsController`:
  - `GET /admin/api/v1/destroyed-fleets?source=discarded|purged`
    - `discarded`: `Fleet.discarded.ransack(...)` → DB search/sort/paginate; serialize like the existing fleet partial + `discardedAt`.
    - `purged`: `PaperTrail::Version.where(item_type: "Fleet", event: "destroy")` excluding item_ids that still exist (`WHERE NOT EXISTS (SELECT 1 FROM fleets ...)`), search via `object ->> 'fid' ILIKE` / `object ->> 'name' ILIKE`, paginate in SQL; serialize id/fid/name/createdBy/destroyedAt(version.created_at)/whodunnit from the version.
  - `POST /admin/api/v1/destroyed-fleets/:id/restore` (discarded): `Fleet.discarded.find(id)` → `undiscard` (cascades to memberships via Phase 3).
  - `POST /admin/api/v1/destroyed-fleets/restore-from-version` (purged): reify + restore (see Phase 6a).
- Routes in `config/routes/admin/api/v1_routes.rb`; authorize via existing `Admin::FleetPolicy` access `[:fleets]` (add `restore` action mapping if needed).
- jbuilder views under `app/views/admin/api/v1/destroyed_fleets/`.

#### Phase 6a — Purged restore logic (the reify wrinkle)
Wrap the whole thing in a transaction. The fleet's `after_create` callbacks fire on save → `setup_default_roles!` (recreates Admin/Officer/Member with **new** UUIDs via `find_or_create_by!(name:)`) and `setup_admin_user` (creates an accepted membership for `created_by` with the rank-0 Admin role).

1. **Reify the Fleet** `destroy` version and save. Default roles + the creator's admin membership now exist.
2. **Roles** (now versioned per Phase 3b): the recreated defaults already cover the standard set. For any *non-default* roles, reify the `FleetRole` `destroy` versions for this fleet and `find_or_create_by(fleet_id:, name:)` so custom roles return without duplicating the defaults. Build an **old-`fleet_role_id` → new-role** map keyed by role `name` (from each reified role's snapshot) for step 3.
3. **Memberships**: for each `FleetMembership` `destroy` version with `object ->> 'fleet_id'` == this fleet id: reify, then `FleetMembership.find_or_initialize_by(fleet_id:, user_id:)` (dedups against the auto-created admin membership), assign reified attributes, and **remap `fleet_role_id`** through the step-2 map. If the old id isn't in the map (role snapshot missing), fall back to `default_member_role`; the creator stays Admin via step 1. `save`.
4. **Inventories**: for each `FleetInventory` `destroy` version for this fleet: reify, `find_or_create_by(fleet_id:, name:)`, save; build an **old-inventory-id → new-inventory** map.
5. **Inventory items**: for each `FleetInventoryItem` `destroy` version whose `object ->> 'fleet_inventory_id'` is in the step-4 map: reify, remap `fleet_inventory_id` to the new inventory, save. Skip items whose parent inventory snapshot is missing.
6. **Guard**: only proceed if the fleet id is genuinely absent from `fleets` (don't clobber a live/discarded fleet).

Not restored (documented + surfaced in the UI): ActiveStorage attachments, `fleet_invite_urls`, `fleet_vehicles` (regenerate from member hangars once memberships are accepted).

### Phase 7 — OpenAPI schema + Orval client
**Commit:** folded into Phase 6 commit or its own `chore(api): schema for destroyed fleets`
- Add `app/api_components/admin/v1/schemas/` classes: `DestroyedFleet`, list wrapper, restore response, and a query/`source` param.
- Add integration tests under `test/integration/admin/api/v1/destroyed_fleets_*_test.rb` describing each endpoint (request params, 200/401/403 responses) — these drive the schema.
- Run `./bin/generate-schema` (regenerates `swagger/admin/v1/schema.yaml`) then `pnpm generate-api-client` (Orval hooks).
- Per repo conventions: never edit `schema.yaml` by hand; run standardrb format+lint after.

### Phase 8 — Admin "Destroyed Fleets" Vue page
**Commit:** `feat(admin-ui): destroyed fleets page`
- `app/frontend/admin/pages/destroyed-fleets/` with `index.vue` + `routes.ts`.
- Two tabs: **Discarded** (high-fidelity restore) and **Purged / legacy** (best-effort, with a visible warning that roles & attachments won't return).
- `BaseTable` + `FilterForm` (Ransack-style filters), Orval `useDestroyedFleets` query + `useRestoreDestroyedFleet` / `useRestoreFromVersion` mutations.
- Restore button per row with a confirm dialog (avoid native `confirm()` — use the app's dialog component).
- Add route `meta` (`title`, `icon: fa-trash-restore`, `access: ["fleets"]`) so the nav entry auto-renders. Add i18n keys.

### Phase 9 — Recover the destroyed fleet
- Once Phases 6–8 ship, use the **Purged** tab to find and restore the affected fleet. Communicate the fidelity caveat (roles/attachments lost; admin re-assigns roles).

### Phase 10 — Tests
- Model: discard/undiscard cascade to memberships; partial-unique-index allows a new fleet with a discarded fleet's fid.
- Request/integration: whodunnit recorded on discard; destroy actions discard (not hard-delete); both restore endpoints (incl. the find_or_initialize dedup and `fleet_role_id` nil-ing).
- Authorization: non-`fleets`-access admin gets 403.

## Open Questions / Risks

- **Membership callbacks under discard** (Phase 3): `remove_fleet_vehicles` / broadcasts run on `after_destroy`, not on discard. Need to decide per-callback whether to mirror them on `after_discard`. Will confirm intent while implementing.
- **`.kept` audit scope** (Phase 5): need to find every member-/public-facing fleet & membership query and add `.kept`. Risk of missing one → discarded fleet leaks into a list. Will enumerate during implementation.
- **Admin index** behavior for normal (non-destroyed) fleet list: show `kept` only? Probably yes, with the destroyed page as the counterpart.
