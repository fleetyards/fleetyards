# Admin Fleet Member Management

Branch: `feat/fleet-soft-delete-and-restore` (extends the soft-delete work)

## Goal

On the **Admin → Fleets → [id] → Members** page, let site admins:

1. **Remove** a member from a fleet (soft-delete / `discard`, consistent with the public flow) — a row action.
2. **Change a member's role** via an **edit form** with a role selector covering every role the fleet has (Admin, Officer, Member, and any custom roles). This subsumes both "promote to admin" and "downgrade to member".

Validation failures surface to the user via the `displayAlert` notification — the form just submits and reports the error, no proactive client-side gating of edge cases.

## Background (current state)

- `Admin::Api::V1::FleetMembersController` is read-only: `index` + `login_as`. Route block `config/routes/admin/api/v1_routes.rb:92` is `only: %i[index]` + a `login-as` member route.
- The members page `app/frontend/admin/pages/fleets/[id]/members.vue:172` exposes only "Login as".
- `FleetMembership` (`app/models/fleet_membership.rb`):
  - `include Discard::Model`; `before_discard :check_if_can_be_destroyed` aborts the discard for a **permanent** role (Admin).
  - `demote` guard skips when `fleet_role.permanent? && fleet_role.fleet_memberships.kept.count == 1` (never demote the last admin).
- `FleetRole`: Admin `rank 0 / permanent`, Officer `rank 10`, Member `rank 20`. `fleet.fleet_roles.ranked` is ascending by rank; `fleet.default_member_role == ranked.last`.
- **Public** side already does step-wise role changes: `Api::V1::FleetMembersController` has `promote`/`demote`/`destroy(discard)` (`app/controllers/api/v1/fleet_members_controller.rb`), and the public UI (`app/frontend/frontend/components/Fleets/MemberActions/Items.vue`) reports failures via `displayAlert`. The admin UX intentionally differs: a direct role-select edit form instead of step-wise buttons.
- **Select component:** `FilterGroup` (`app/frontend/shared/components/base/FilterGroup/index.vue`) is the app's reusable select — `v-model` + `:options` (`FilterOption[]` = `{ value, label }`), plus `:searchable` / `:nullable` / `:label`. Already used for selects in forms (e.g. `InventoryItemModal`) and in the admin filter groups (`base/FleetFilterGroup`).

## Design decisions

- **Role change = edit form** (per product decision), not promote/demote buttons. The form posts the chosen `fleetRoleId`; the server validates and may reject. Admin can assign any of the fleet's roles directly.
- **Removal = discard** (row action), matching the public flow.
- **Permanent-role handling = "same as public":**
  - Removal: `check_if_can_be_destroyed` blocks discarding an Admin-role member → `422`. (To remove an admin, change their role first.)
  - Role change away from a permanent role: blocked only when it's the **last** admin (mirror `demote`'s guard) → `422`.
  - No proactive client gating for these — the form submits and the `422` message is shown via `displayAlert`.
- **Role options source:** expose the fleet's roles on the admin **Fleet** payload (`fleetRoles: [{ id, name, permanent, rank }]`) so the members/edit page — which already receives the `fleet` prop — can populate the selector with no extra request.
- **Select control:** reuse the existing `FilterGroup` component for the role picker (`:options` built from `fleet.fleetRoles`, `value` = role id, `label` = role name). No new component needed.

## API shape

- `GET  /admin/api/v1/fleets/{fleet_id}/members/{id}` → `AdminFleetMember` (loads the edit form).
- `PATCH /admin/api/v1/fleets/{fleet_id}/members/{id}` body `{ fleetRoleId }` → `200 AdminFleetMember` / `422`.
- `DELETE /admin/api/v1/fleets/{fleet_id}/members/{id}` → `204` / `422`.
- Fleet roles ride along on the existing `GET /admin/api/v1/fleets/{id}` (`fleetRoles`).

## Changes

### 1. Routes — `config/routes/admin/api/v1_routes.rb`
```ruby
resources :fleet_members, path: "members", only: %i[show update destroy] do
  member do
    get "login-as", to: "fleet_members#login_as"
  end
end
```

### 2. Controller — `app/controllers/admin/api/v1/fleet_members_controller.rb`
- Add `:show, :update, :destroy` to the `set_member` `before_action`.
- `show`: render the member (AdminFleetMember).
- `update`:
  - `target = @fleet.fleet_roles.find_by(id: params[:fleet_role_id])`; `422` invalid-role if nil.
  - Last-admin guard: if `@member.fleet_role&.permanent?` and `target` is not permanent and `@member.fleet_role.fleet_memberships.kept.count == 1` → `422` (`messages.admin.fleet_members.cannot_demote_last_admin`).
  - `@member.update(fleet_role: target)` → render `show` on success, `ValidationError` (`422`) on failure.
- `destroy`: `return head :no_content if @member.discard` else `ValidationError` (`422`) (covers permanent-role abort).
- Permit `fleet_role_id` in a strong-params helper.

### 3. Views
- `app/views/admin/api/v1/fleet_members/show.json.jbuilder` — single `AdminFleetMember`; reuse the attribute shape the `index` view emits per member. Add `roleId` (`fleet_role_id`) to the member payload so the form can preselect the current role.
- `app/views/admin/api/v1/fleets/show.json.jbuilder` (or the fleet partial) — add `fleetRoles` array (`id`, `name`, `permanent`, `rank`), ordered `ranked`.

### 4. Schema (api_components + generation)
- `app/api_components/admin/v1/schemas/inputs/admin_fleet_member_update_input.rb`: `fleetRoleId` `{type: :string, format: :uuid}`, `required %w[fleetRoleId]`, `additionalProperties: false`.
- Add `roleId` to `admin_fleet_member.rb`.
- Add `fleetRoles` array to the admin `fleet.rb` schema (+ a small `AdminFleetRole` component: `id`, `name`, `permanent`, `rank`).
- Integration doc-tests drive generation (template: `fleet_members_login_as_test.rb`):
  - `fleet_members_show_test.rb` — `GET …/members/{id}`, op `fleetMember`, `200/404/403/401`.
  - `fleet_members_update_test.rb` — `PATCH …/members/{id}`, op `updateFleetMember`, body `$ref` input, `200/422/404/403/401`.
  - `fleet_members_destroy_test.rb` — `DELETE …/members/{id}`, op `removeFleetMember`, `204/422/404/403/401`.
- **Never edit `schema.yaml` by hand.** Run `./bin/generate-schema`, then standardrb + `pnpm lint`. Commit the regenerated `fyAdminApi` client as its own commit.

### 5. Frontend
- **Edit page** `app/frontend/admin/pages/fleets/[id]/members/[memberId]/edit.vue` + `routes.ts` entry (model on `fleets/[id]/edit.vue`):
  - `useForm` with a single `fleetRoleId` field, initial = current `roleId`.
  - `FilterGroup` bound to `fleetRoleId`, `:options` = `fleet.fleetRoles.map(r => ({ value: r.id, label: r.name }))`, `:searchable="false"`.
  - `FormActions` (save/cancel). On submit call `updateFleetMember`; `.catch` → `displayAlert({ text: error message })`; on success invalidate the members query + navigate back to the members list.
- **Members table** `members.vue`: add row actions next to "Login as":
  - **Edit role** → router push to the edit page.
  - **Remove** → `displayConfirm` then `removeFleetMember`; `.catch` → `displayAlert`; success → `refetch`. Hidden for Admin-role members (their removal is blocked server-side anyway).

### 6. i18n
Add to `config/locales/en/...` (+ other locales as lint requires):
- `actions.fleet.members.editRole`, `.remove`.
- `headlines.admin.fleets.memberEdit`, form label `labels.fleet.members.role`.
- `messages.confirm.fleet.members.remove`.
- Errors: `messages.admin.fleet_members.invalid_role`, `.cannot_demote_last_admin`; reuse `activerecord.errors.models.fleet_membership...cannot_destroy_from_permanent_role` for removal.

### 7. Tests (Minitest — repo has no `spec/`)
- update → assign Admin role: 200, role changed.
- update → assign Member role from Officer: 200.
- update → demote the **last** admin: 422, unchanged.
- update → invalid/foreign `fleetRoleId`: 422.
- destroy → 204, membership discarded (`kept` excludes it).
- destroy → Admin-role member: 422, still kept.
- show + 404/403/401 paths (model on `login_as`).
- Fleet show includes `fleetRoles`.

## Out of scope
- Hard-deleting memberships; bulk actions.
- Creating/editing the fleet's role definitions from admin (only assignment of existing roles).

## Sequencing / commits
1. Backend: routes + controller + show jbuilder + fleet `fleetRoles` payload (+ controller tests).
2. Schema: input/components + integration doc-tests → `./bin/generate-schema`; regenerated client as a separate commit.
3. Frontend: edit page + routes + members.vue actions + i18n.
4. Final: standardrb + `pnpm lint`, run targeted tests.
