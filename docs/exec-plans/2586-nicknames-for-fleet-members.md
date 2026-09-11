# Nicknames for fleet members

## Goal
A fleet admin can set, change, and clear a per-fleet nickname on any member, and that nickname is what the fleet sees throughout the members UI while the real username remains the identifier everywhere it links or resolves.

## Context
Fleet admins want to label members with the name the fleet actually knows them by — an in-game handle, a callsign, a shortened form — instead of the Fleetyards username. Today `fleet_memberships` carries no free-text field at all, and the public API has no member-update endpoint, so both the storage and the write path are new.

Resolves #2586

GitHub issue: https://github.com/fleetyards/fleetyards/issues/2586

> **Label correction needed.** The issue carries `size/S` ("One PR, no migration"). A migration is unavoidable — see D1. Still one PR, but the label should move to a size that permits a migration.

## Decisions

### D1 — Store the nickname on `fleet_memberships`, not `users`
The issue scopes nicknames to a fleet ("Admins could add nicknames for members"). A user belongs to many fleets, so a nickname on `users` would leak one fleet's label into every other fleet and would be writable by the wrong admins. The nickname is a property of the *membership*.

There is no existing free-text column on `fleet_memberships` to reuse (`db/schema.rb:638-660` — the only string columns are `aasm_state`, `invited_by`, `used_invite_token`), so a migration adding `nickname:string` is required. Rejected: overloading `used_invite_token`; a separate `fleet_member_nicknames` table (a 1:1 side table buys nothing and costs a join on the hot members list).

### D2 — New `PUT /fleets/{fleetSlug}/members/{username}`, not the self-service membership endpoint
`Api::V1::FleetMembersController` has no `update` action. The only existing `update` is `Api::V1::FleetMembershipsController#update`, which is deliberately self-service — it acts on `current_user`'s own membership and cannot address another member. Reusing it would require inventing a "which member" parameter on an endpoint whose whole contract is "mine".

The new action lives beside `promote`/`demote` on `FleetMembersController`, which already resolves `:username` to a member via `set_member` (`app/controllers/api/v1/fleet_members_controller.rb:104-111`).

### D3 — Authorize with the existing `fleet:memberships:update` privilege
`promote?`, `demote?`, `accept_request?`, and `decline_request?` are all gated on `["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"]`, and `CAPABILITY_PRIVILEGES[:update_members]` (`app/models/fleet_membership.rb:129`) already exposes exactly that set to the frontend as `capabilities.updateMembers`. Setting a nickname is the same class of act.

Consequence: **no new capability**, so `test/models/fleet_membership_capabilities_test.rb` needs no change, and the frontend gates on a boolean it already receives.

The new rule must be named `update_nickname?`, not `update?` — `FleetMembershipPolicy#update?` is the self-service rule (`app/policies/fleet_membership_policy.rb:33-35`, `record.user_id == user.id`) and widening it would let any member edit their own membership through a path that is meant to stay narrow. The controller authorizes explicitly against the new rule.

### D4 — A rule-scoped `params_filter`, leaving the shared one untouched
`params_filter` (`app/policies/fleet_membership_policy.rb`) is shared by every action on the policy and permits `[:primary, :ships_filter, :hangar_group_id]` to anyone with a membership. Widening it would have let a fleet admin flip another member's `primary` flag and ships filter through the new endpoint.

Action Policy supports rule-scoped filters — `params_filter(:create)` in `app/policies/fleet_policy.rb:48` is the precedent, selected at the call site with `authorized(params, as: :create)`. So `params_filter(:update_nickname)` permits `:nickname` and nothing else, and the shared filter is not touched at all. It needs no privilege check of its own because the action authorizes `update_nickname?` before reading params, exactly as `params_filter(:create)` relies on `create?`.

### D5 — Nickname is optional, not unique, length-capped; username stays the identifier
A nickname is a label, not a handle. Two members may plausibly share one, and enforcing per-fleet uniqueness would make the admin UI fail in a way the issue never asked for. Blank input clears it (normalize `""` → `nil`).

The username remains what every link, lookup, and route resolves on — `MemberLinks/index.vue:26` (`/hangar/${member.username}`) and `set_member`'s `normalized_username` lookup are untouched.

### D6 — Display nickname primary, username secondary, at one choke point
`components/Fleets/MemberName/index.vue` is the single component rendering `member.username` for the list, the invites list, and the mobile detail modal. Rendering the nickname there (with the username kept visible beneath/beside it, never replaced) covers every surface at once and keeps the real identity discoverable. When no nickname is set, the component renders exactly as it does today.

## What changed

### Phase 1 — Backend: storage, write path, payload
1. Migration `add_nickname_to_fleet_memberships` — `add_column :fleet_memberships, :nickname, :string`. Run `bin/rails db:migrate` and let the annotation update `app/models/fleet_membership.rb`'s schema block.
2. `app/models/fleet_membership.rb` — length validation (max 255, `allow_blank`), a `before_validation` normalizing blank to `nil`, and add `nickname` to `ransackable_attributes` (`:75-78`) so admins can search by it.
3. `app/policies/fleet_membership_policy.rb` — add `update_nickname?` gated on `["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"]`; add `params_filter(:update_nickname)` permitting only `:nickname` (D4).
4. `app/controllers/api/v1/fleet_members_controller.rb` — `update` action plus a new `update.jbuilder`. The lookup is extracted from `set_member` into `find_member!` so `update` can authorize `update_nickname?` instead of the `update?` that a `set_member` before_action would infer from the action name.
5. `config/routes/api/fleets_routes.rb:18` — add `:update` to the `fleet_members` `only:` list.
6. `app/controllers/concerns/fleet_member_filters_concern.rb:4-13` — permit `:nickname_cont` in `member_query_params`.
7. `app/views/api/v1/fleet_members/_base.jbuilder` — `json.nickname member.nickname` beside `json.username` (line 5).
8. Bump the cache key `"v1"` → `"v2"` in `app/views/api/v1/fleet_members/_fleet_member.jbuilder` — a new rendered field does not bust a key derived from an unchanged record. The admin partial is **not** bumped: its payload is a separate `_base.jbuilder` that does not render the nickname, so a bump there would flush a cache for nothing.

### Phase 2 — API schema and generated clients
1. `app/api_components/v1/schemas/fleets/fleet_member.rb` — add `nickname` (nullable string) to the properties. The component sets `additionalProperties: false` (`:51`), so the jbuilder field breaks schema validation until this lands. Leave it out of `required`.
2. New `app/api_components/v1/schemas/inputs/fleet_member_update_input.rb` — `nickname` only. Per AGENTS.md:244-330, the request body must `$ref` a component, never an inline type.
3. `app/api_components/v1/schemas/queries/fleet_member_query.rb` — add `nicknameCont` (also `additionalProperties: false`, `:31`).
4. New `test/integration/api/v1/fleets_members_update_test.rb` — modelled on the PUT spec in `test/integration/api/v1/fleets_membership_test.rb:64-80`. Declare actions in alphabetical order (see that file's comment at `:11-12`) so the generated YAML ordering stays stable.
5. Run `bin/generate-schema`, then `bin/generate-asyncapi` and `bin/generate-cable-client` — `FleetMember` is broadcast over `FleetMembersChannel` (`test/asyncapi/fleet_members_channel_test.rb:15`), so the cable schema and `app/frontend/services/fyCable/models/FleetMember.ts` go stale otherwise. Never hand-edit `swagger/`, `asyncapi/`, or `app/frontend/services/fy*Api/`.

### Phase 3 — Frontend
1. `components/Fleets/MemberName/index.vue` — render nickname primary with username secondary when `member.nickname` is present; unchanged output when it is not (D6).
2. New nickname edit modal, modelled on `components/Fleets/MemberModal/index.vue` (vee-validate `useForm` + orval mutation + `comlink.emit`).
3. `components/Fleets/MemberActions/Items.vue` — an "Edit nickname" entry gated on the existing `canUpdateMembers` (`:53-62`), opening the modal.
4. `components/Fleets/MembersList/index.vue` — verify the `col-username` slot (`:101-114`) and column widths (`:49-88`) still read well with a two-line name cell.
5. `components/Fleets/MembersFilterForm/index.vue` — left alone; see "Not in scope".

### Phase 4 — i18n and tests
1. Frontend strings in `app/frontend/translations/<locale>/{labels,actions,messages,validationError}.json` — `labels.fleet.members.nickname`, `actions.fleet.members.editNickname`, success/failure messages. **All 7 locales by hand** (`de en es fr it zh-CN zh-TW`); Crowdin is not in use and `enableFallback` hides every gap, so en-only keys silently never reach the others.
2. Backend strings — `config/locales/<locale>/activerecord.yml` (attribute name under `fleet_membership:`, `:136-141`) and `validation_error.yml` (`fleet_members:`, `:22`), all 7 locales.
3. `test/models/fleet_membership_test.rb` — validation and blank-normalization coverage.
4. `test/factories/fleet_memberships.rb` — a `:with_nickname` trait.
5. `bin/ruby-lint` (standardrb — `bin/rubocop` passes on code CI rejects) and `bin/rails test` on the touched paths.

## Intent Verification

- [ ] **An admin can set a nickname** — a member with `fleet:memberships:update` can PUT a nickname onto another member and see it persisted.
- [ ] **A non-admin cannot** — a plain accepted member PUTs a nickname onto another member and is rejected; they also cannot set one on themselves via the self-service membership endpoint.
- [ ] **Clearing works** — submitting an empty nickname stores `nil`, and the UI falls back to the username.
- [ ] **The fleet sees it** — the nickname appears in the members list, the invites list, and the mobile detail modal for every member of the fleet.
- [ ] **Username still resolves** — the hangar link and the `:username` route param are unaffected by a nickname being set.
- [ ] **Live update** — a nickname change propagates over `FleetMembersChannel` without a reload (the existing `after_commit :broadcast_update` covers this; confirm the badge/list actually repaints).
- [ ] **Schema is green** — `bin/generate-schema` produces no unstaged drift and `api-schema-check` passes.
- [ ] **No stale cache** — a member rendered before the change shows their nickname immediately after it (the `"v2"` bump).

## Key files

| File | Role |
|------|------|
| `db/migrate/*_add_nickname_to_fleet_memberships.rb` | New column |
| `app/models/fleet_membership.rb` | Validation, normalization, ransack whitelist |
| `app/policies/fleet_membership_policy.rb` | `update_nickname?` rule + `params_filter` branch |
| `app/controllers/api/v1/fleet_members_controller.rb` | New `update` action |
| `config/routes/api/fleets_routes.rb` | Route for the new action |
| `app/controllers/concerns/fleet_member_filters_concern.rb` | `nickname_cont` query param |
| `app/views/api/v1/fleet_members/_base.jbuilder` | Renders the field |
| `app/views/api/v1/fleet_members/_fleet_member.jbuilder` | Cache key bump |
| `app/views/admin/api/v1/fleet_members/_fleet_member.jbuilder` | Cache key bump |
| `app/api_components/v1/schemas/fleets/fleet_member.rb` | Response component (`additionalProperties: false`) |
| `app/api_components/v1/schemas/inputs/fleet_member_update_input.rb` | New request component |
| `app/api_components/v1/schemas/queries/fleet_member_query.rb` | Filter component |
| `test/integration/api/v1/fleets_members_update_test.rb` | Generates the OpenAPI path |
| `app/frontend/frontend/components/Fleets/MemberName/index.vue` | Display choke point |
| `app/frontend/frontend/components/Fleets/MemberActions/Items.vue` | Admin entry point |
| `app/frontend/frontend/components/Fleets/MemberModal/index.vue` | Template for the edit modal |
| `app/frontend/translations/*/` | 7 locales, by hand |

## Not in scope (deferred)
- **Nicknames in the Discord `/fleet members` command** (`lib/discord/commands/fleet_members.rb`) — a separate surface with its own rendering and tests; worth a follow-up once the core lands.
- **Nicknames in the admin panel** (`app/frontend/admin/pages/fleets/[id]/members*`) — the admin panel's member payload is a separate thinner component; the issue asks for fleet admins, not site admins.
- **Member-editable nicknames** — the issue explicitly says admins. Letting members set their own is a product decision, not an oversight.
- **Per-fleet uniqueness** — see D5.
- **E2E coverage of the members page** — `test/playwright/e2e/Fleet.spec.ts` has no member references today; adding the first one is its own piece of work.
- **Searching the members list by nickname** — `nicknameCont` is permitted and in the schema, so an API consumer can filter on it, but the UI search box still only sends `usernameCont`. A single box matching either needs a new query param: ransack does **not** resolve `ransack_alias` inside an `_or_` chain, so `username_or_nickname_cont` builds `fleet_memberships.username` and blows up on a column that does not exist. The working form is `user_username_or_nickname_cont`, verified against the dev database. Changing what `usernameCont` means would be a silent break for existing API callers, so a combined search wants its own parameter.

## Open questions
- Should a member be able to *see* that they have a nickname, and who set it? The plan shows it to everyone in the fleet, with no attribution.
- Should the nickname or the username be the sort key when the list is sorted by name? The plan leaves sorting on `user_username` as-is.

## Discovery Log

- **2026-09-11** Initial research and plan creation. Confirmed: no `nickname`/`alias`/`display_name` exists in any member/user context; the public API has no member-update action; `update_members` / `fleet:memberships:update` already exists as a capability so no capability test changes are needed; `FleetMember` is broadcast over cable, so three generators must run, not one.
- **2026-09-11** Phases 1 and 2 landed. Three findings changed the shape:
  - **`params_filter` is rule-scoped.** D4 originally widened the shared filter behind a privilege check. `params_filter(:update_nickname)` is strictly better — the shared filter is untouched, so there is no path by which this endpoint can write `primary`, `ships_filter`, or `hangar_group_id`.
  - **A widened body is rejected, not ignored.** `additionalProperties: false` on the input component is enforced by request validation, so a body carrying extra attributes returns 400 rather than silently dropping them. The test asserts the 400 and that nothing was written.
  - **The cable schema fails the suite before the REST schema does.** Adding the jbuilder field made six tests raise `AsyncapiCable::Error: object property at /nickname is a disallowed additional property` from `broadcast_update`, well before any OpenAPI check. `bin/generate-asyncapi` is not optional here, and it has to run before the tests can go green.
  - Backend i18n needed only `activerecord.attributes.fleet_membership.nickname` — `validation_error.fleet_members.update` already existed in all 7 locales.
  - Generated schema diff is purely additive: 70 lines, no deletions.
- **2026-09-11** Phases 3 and 4 landed.
  - `MemberContact` (`components/base/MemberContactMenu/types.ts`) gained an optional `nickname`. It is deliberately structural rather than tied to `FleetMember`, and the other surfaces that use it (vehicle owner, inventory manager) simply never pass one.
  - The action button gates on a new `canUpdateNickname` rather than the existing `canUpdateMembers`, which excludes the current user. The server applies no such self-exclusion to `update_nickname?`, so reusing `canUpdateMembers` would have hidden the button from an admin editing their own nickname.
  - The modal takes `fleetSlug`, not a whole `Fleet`: `MemberActions` never has the fleet object, only `route.params.slug`.
  - Frontend i18n needed four new keys across 7 locales, all hand-translated. `actions.save` already existed; `messages.fleet.members.update` exists but reads "Settings saved." and belongs to the self-service settings page, so the nickname got its own messages.
  - Verified green: 117 fleet-member integration tests, 32 model/asyncapi tests, 559 vitest tests, `bin/ruby-lint`, eslint, prettier, and `lint:ts` (exit 0).

## Progress
- [x] Phase 1 — Backend: storage, write path, payload
- [x] Phase 2 — API schema and generated clients
- [x] Phase 3 — Frontend
- [x] Phase 4 — i18n and tests
