# Squadron ranks: Leader, Officer, Member

Working plan for #5176. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Every squadron membership holds one of its fleet's four squadron ranks (Leader, Co-Leader, Officer, Member), with at most one Leader and one Co-Leader per squadron. Leaders, Co-Leaders and Officers can manage their own squadron's roster. Leaders and Co-Leaders can change ranks. The rank names can be renamed in the fleet settings, and the rank shows on the roster and on the member badges.

## Open questions

- **Who can remove a Leader?** May an Officer remove the Leader from the squadron? Can the Leader step down to an empty Leader slot?
- **Team squadrons too?** Ranks on `team: true` squadrons, or ordinary squadrons only?

## What changed

### Phase 1 — Data model
1. A `fleet_squadron_roles` table: `fleet_id`, `key` (leader / co_leader / officer / member, unique per fleet), `name`, `position`. The key is fixed. It carries the order, the single-holder limit and the privileges, so renaming a rank changes none of them. No lexorank and no `resource_access` while the four slots are fixed.
2. `FleetSquadronRole` model: `KEYS`, `SINGLE_KEYS = %w[leader co_leader]`, and the privileges derived from the key. Leader and Co-Leader manage members and change ranks, Officer manages members, Member does neither.
3. `setup_default_squadron_roles!`, called from `Fleet#after_create` and from `Fleets::PurgedFleetRestorer`.
4. `fleet_squadron_memberships.fleet_squadron_role_id` (FK). A data migration seeds the ranks for existing fleets and backfills every membership to Member, then the column becomes not null.
5. Validation: the rank must belong to the squadron's fleet, like `membership_belongs_to_same_fleet`. New memberships default to the fleet's Member rank.
6. One holder per single rank: a validation that locks the squadron row, like `exclusive_squadron_is_the_only_one` does, plus a DB guard. A partial index can't reach the role's key, so `fleet_squadron_memberships` gets a denormalised `single_role_key` (null unless leader or co_leader) and a unique index on (fleet_squadron_id, single_role_key).

### Phase 2 — Policies and capabilities
1. `FleetSquadronMembershipPolicy`: create?/destroy?/update? pass on the existing fleet privileges, **or** when the caller's own rank in *this* squadron manages members. Changing a rank needs a Leader or Co-Leader rank (or the fleet privilege). Neither Officers nor Co-Leaders can change the Leader's rank. The squadron goes into the policy context.
2. A per-squadron `capabilities` block on the squadron payload (`manageMembers`, `manageRanks`), because `membership.capabilities.manageSquadronMembers` is fleet-wide and can't say "Leader of this squadron".
3. Policy tests: there is no `FleetSquadronMembershipPolicy` test file yet, so add one.

### Phase 3 — API
1. `GET /fleets/:slug/squadron-roles` (index) for the rank select, and `PUT /fleets/:slug/squadron-roles/:key` to rename a rank. Renaming needs `fleet:squadrons:manage` (or `fleet:manage`).
2. The update input gets `fleetSquadronRoleId`, and `createdAt` becomes optional. The create input gets an optional rank.
3. The `squadrons` block in `_fleet_member.jbuilder` and `FleetSquadronRef` gain `role { id, name, slug }`. Keep the `list_endpoint_query_counts_test` budget.
4. Locales: `validation_error.fleet_squadron_members.*` and the privilege labels, in all seven locales.
5. Regenerate the schema and check oasdiff (`createdAt` going optional changes the request side only).

### Phase 4 — Frontend
1. Regenerate the Orval client.
2. Turn `SquadronMemberDateModal` into a member edit modal with a rank select (shown only with `manageRanks`).
3. Add a rank column to the squadron roster in `MembersList`. The badge tooltip in `MemberAvatar` gets "Squadron · Rank".
4. The roster page's `canManageMembers` reads the squadron capabilities instead of the fleet-wide one.
5. A section in `settings/squadrons.vue` for renaming the four ranks.
6. Translations in all seven locales.

## Intent Verification

- [ ] **Rank on the membership** — every `FleetSquadronMembership` has a rank from its fleet's ranks. New members start as Member.
- [ ] **Editable by managers** — a fleet officer with `fleet:squadrons:members:manage` and a Squadron Leader can both change a rank through the update endpoint and the roster UI.
- [ ] **Own-squadron privileges** — a Squadron Officer without fleet squadron privileges can add/remove members of their own squadron and gets 403 on another squadron. A Squadron Member can do neither.
- [ ] **Shown on roster and badges** — the roster has a rank column, and the member badge tooltip shows the rank.
- [ ] **Existing fleets** — after the data migration every existing fleet has the three ranks and every existing membership is Member.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_squadron_membership.rb` | Join, gets the rank reference and same-fleet validation |
| `app/models/fleet_role.rb` | Pattern for seeded, ranked, privileged rows |
| `app/models/fleet.rb` | `after_create` seeding |
| `app/services/fleets/purged_fleet_restorer.rb` | Seeding on restore |
| `app/policies/fleet_squadron_membership_policy.rb` | Own-squadron privilege checks |
| `app/policies/fleet_contract_assignment_policy.rb` | Precedent: a role on the join granting rights |
| `app/controllers/api/v1/fleet_squadron_members_controller.rb` | Update params, rank input |
| `app/views/api/v1/fleet_members/_fleet_member.jbuilder` | `squadrons` badge block |
| `app/api_components/v1/schemas/fleets/squadrons/fleet_squadron_ref.rb` | Badge schema (`additionalProperties: false`) |
| `app/api_components/v1/schemas/inputs/fleet_squadron_member_update_input.rb` | `createdAt` becomes optional |
| `app/frontend/frontend/pages/fleets/[slug]/squadrons/[squadron]/members.vue` | Roster page |
| `app/frontend/frontend/components/Fleets/MembersList/index.vue` | Rank column |
| `app/frontend/frontend/components/Fleets/MemberAvatar/index.vue` | Badge tooltip |
| `app/frontend/frontend/components/Fleets/Squadrons/SquadronMemberDateModal/index.vue` | Becomes the edit modal |
| `app/frontend/frontend/pages/fleets/[slug]/settings/squadrons.vue` | Rank renaming |

## Not in scope (deferred)

- **Moving a member between squadrons** — listed separately in the squadrons backlog.
- **Ranks beyond the four, and reordering them**: decided out of this issue. The rows leave room for both.
- **Discord role per squadron rank** — `FleetRole` has `discord_role_id`, but squadrons only sync a channel so far.

## Discovery Log

- **2026-10-02** Initial research and plan creation. A per-squadron rank was already in the squadrons backlog (`git show a7deea5968:docs/exec-plans/fleet-squadrons.md`). `fleet_squadrons.rank` is the squadron's lexorank position, so the membership side uses `fleet_squadron_role` to avoid the name clash.
- **2026-10-02** Four fixed slots (one Leader, one Co-Leader, many Officers and Members), renameable in settings. The slot key moves the order and the privileges off `rank`/`resource_access`, which `FleetRole` needs only because its rows are free-form.

## Progress

- [ ] Phase 1 — Data model
- [ ] Phase 2 — Policies and capabilities
- [ ] Phase 3 — API
- [ ] Phase 4 — Frontend
