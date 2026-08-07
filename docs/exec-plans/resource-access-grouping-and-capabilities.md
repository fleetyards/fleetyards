# Resource Access — grouped catalog + typed capability contract

## Goal

Turn `resourceAccess` from a loose, hand-maintained privilege list into a
grouped, strongly-typed contract with a single backend source of truth, and
give the management UIs (admin editor, fleet role editor) a proper grouped
catalog to render — without forcing a record where none exists.

This builds on a known pattern: exposing ActionPolicy rules to the API as a
typed contract. fleetyards runs on ActionPolicy, so the mechanism transfers
directly; only the *record-embedded* variant of it does not (see D1).

## Background (current state)

- **Admin authorization is purely subject-scoped.** `Admin::BasePolicy#manage?`
  is `user.has_access?(resource_access)` and never touches `record`;
  `index?/show?/create?` all `alias_rule … to: :manage?`. So "may this admin
  create a Model" has no record and never will — it is a capability of the
  user, not of a row.
- `AdminUser.resourceAccess` is already the subject-scoped capability list on
  the session payload — just flat, hand-listed in the enum, and re-checked
  client-side (`sessionStore.hasAccessTo("models")`).
- `FleetRole.resourceAccess` is the *assigned* privilege set on a role, edited
  in `roles.vue` and re-checked fleet-wide via
  `checkAccess(membership.fleetRole.resourceAccess, [...])`.
- Enums added in PR #4212: `FleetRoleResourceAccessEnum` (sourced from
  `FleetRole.all_available_privileges` — no drift) and
  `AdminUserResourceAccessEnum` (**hand-listed — drifts**).
- Grouping exists only latently: fleet privileges encode it in the string
  (`fleet:<group>:<action>`), admin privileges are flat with no groups.
  `roles.vue` hardcodes the implication rules (`fleet:manage` implies all,
  `fleet:<group>:manage` implies its group) in `isImpliedByManage`.

## Design decisions

### D1 — Do not force the record-embedded `permissions` object onto admin

A record-scoped `permissions: {update, destroy}` object fits resources with a
real row. Admin (and most fleet gating) is subject-scoped: the capability
belongs to the user/role, evaluated against a class, not a record. We keep
those on the `me`/session payload, not embedded per row.

### D2 — Three scopes, chosen per rule

| Scope | fleetyards example | Home |
|-------|--------------------|------|
| record-scoped | "may I edit *this* inventory" | `permissions` on the record payload |
| subject-scoped | "may this admin manage Models" / "may I do X in this fleet" | typed capability list on `me` / membership |
| parent-scoped | "may I create a role in *this* fleet" | capability on the parent payload |

This PR line focuses on **subject-scoped + grouping**, because that is where
the drift and the management-UX pain actually are. Record-scoped `permissions`
is a separate, additive follow-up.

### D3 — One hierarchical catalog per domain as the single source of truth

Group → privileges lives in Ruby. Everything else is derived: the flat enum
(wire + validation), the grouped catalog schema (management UI), and the
implication rules. Mirrors the existing precedent where enum components source
Ruby constants (PR #4212, `DockTypeEnum ← Dock.dock_types.keys`).

### D4 — Separate the two consumers

- **Runtime gating** stays flat (booleans / list membership) — cheap, no group
  structure needed.
- **Management UI** consumes a *static* grouped catalog (available options +
  group + implication). It is constant per deploy, not per user, so it ships as
  its own schema, not folded into the user's assigned list.

### D5 — Opt-in, reference-slice-first, no enforced convention test yet

Land the catalog + admin slice first (the drift fix), then fleet, then the
evaluated-capability channel. Defer a drift convention test until 2–3
consumers exist.

## API shape

```ts
// Static grouped catalog (management UI) — constant per deploy
interface ResourceAccessGroup {
  key: string;              // "shipData" | "roles" | ...
  privileges: string[];     // enum values in this group
  managePrivilege?: string; // the "*:manage" that implies the whole group
}
// GET /admin/api/v1/session (me)  → resourceAccessCatalog: ResourceAccessGroup[]
// GET /api/v1/fleets/:slug/roles  → (catalog served alongside, or on fleet payload)

// Assigned set stays the typed enum array (PR #4212), now group-aware in the UI:
//   AdminUser.resourceAccess: AdminUserResourceAccessEnum[]
//   FleetRole.resourceAccess: FleetRoleResourceAccessEnum[]
```

## Changes

### Phase 1 — Grouped catalog SSOT + kill the admin enum drift

1. **`app/models/admin_user.rb`** — introduce the grouped catalog and derive
   the flat list:
   ```ruby
   RESOURCE_ACCESS = {
     ship_data: %w[models model_modules components manufacturers vehicles images],
     community: %w[fleets users supporters],
     system:    %w[admins oauth_applications maintenance imports features workers pghero rsi-api-status stats],
   }.freeze
   AVAILABLE_PRIVILEGES = RESOURCE_ACCESS.values.flatten.freeze
   ```
2. **`app/api_components/shared/v1/schemas/enums/admin_user_resource_access_enum.rb`**
   — replace the hand-listed array with `::AdminUser::AVAILABLE_PRIVILEGES`
   (matches how `FleetRoleResourceAccessEnum` already sources its constant).
3. **Fleet catalog** — add a `FleetRole.privilege_groups` class method deriving
   groups from the existing per-model `AVAILABLE_PRIVILEGES` (Fleet /
   FleetMembership / FleetInviteUrl / FleetVehicle / FleetRole / FleetInventory),
   so fleet gets the same grouped structure without a second source of truth.
4. Regenerate: `./bin/generate-schema` → format → lint (standardrb + tsc).

> Phase 1 is the small, drop-into-the-open-PR piece: it removes the drift I
> flagged on #4212 and lays the catalog other phases build on. No API-surface
> change beyond the enum source.

### Phase 2 — Grouped catalog on the payloads (management UI)

1. New schema component `ResourceAccessGroup` (+ admin variant if the shapes
   diverge).
2. Admin session (`app/controllers/admin/api/v1/sessions_controller.rb` /
   its jbuilder) emits `resourceAccessCatalog` from `AdminUser::RESOURCE_ACCESS`.
3. Fleet roles response carries the fleet catalog (from `privilege_groups`).
4. Frontend: `roles.vue` and the admin editor render from the catalog; move
   the `isImpliedByManage` implication out of the component and onto the
   catalog metadata (`managePrivilege`).
5. Tests: request specs assert the catalog shape; `run_test!` enforces it.

### Phase 3 — Subject-scoped *evaluated* capabilities (deferred)

A `PolicyContract`-style mechanism for the record-less case: a policy declares
its exposed rules, evaluated against the current user/class (no record),
shipped as a typed boolean object on `me`. Lets the frontend replace
`hasAccessTo`/`checkAccess` with `me.capabilities.x`. Additive; does not change
Phases 1–2.

## Out of scope (for now)

- **Record-scoped `permissions` object** — separate line, only for the
  genuinely per-row fleet cases.
- **Removing `User.resourceAccess`** — still always `[]` with no consumers;
  either delete or repurpose as the Phase 3 capability channel.
- **Caching** — capabilities recomputed per render; optimize later.

## Sequencing / commits

1. `feat(admin): grouped resource-access catalog + enum from constant` (Phase 1)
2. `feat(api): expose grouped resource-access catalog on payloads` (Phase 2 backend)
3. `refactor(frontend): render privilege editors from catalog` (Phase 2 frontend)
4. Phase 3 as its own PR once 1–2 are approved.
