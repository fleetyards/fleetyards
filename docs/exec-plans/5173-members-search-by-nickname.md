# Members list: search by nickname as well as username

Working plan for #5173. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The fleet members search box finds a member by their username or their fleet nickname.

## Open questions
- None — param name and scope are decided in the issue body.

## What changed

### Phase 1 — API
1. `FleetMemberQuery::FILTERS` gains `searchCont` (shared with the squadron member query).
2. `FleetMemberFiltersConcern` permits `:search_cont` and rewrites it to `user_username_or_nickname_cont` — never `username_or_nickname_cont`, which ransack resolves against a non-existent `fleet_memberships.username` column and only fails at execution.
3. `./bin/generate-schema`; regenerate the frontend client.

### Phase 2 — Frontend
1. `MembersFilterForm` (and `SquadronMembersFilterForm`) bind the header search to `searchCont` instead of `usernameCont`.
2. `filters.fleets.members.username` placeholder replaced by `filters.fleets.members.search` (label + placeholder, "Username or nickname") in all 7 locales, by hand. The members box had no label key at all before.
3. Update `useMembersView.spec.ts` fixtures if the shared keys change.

### Phase 3 — Tests
1. Request test in `test/integration/api/v1/fleets_members_index_test.rb`: a member whose nickname matches and username does not is returned via `searchCont`; username match still works.
2. Same for the squadron members index.

## Intent Verification

- [ ] **The members search box matches username or nickname** — typing a nickname in the members header search lists that member
- [ ] **Request test for a nickname-only match** — passes, and the query actually executes (not just builds)

## Key files

| File | Role |
|------|------|
| `app/controllers/concerns/fleet_member_filters_concern.rb` | Permitted `q` params for members, squadron members, stats |
| `app/api_components/v1/schemas/queries/fleet_member_query.rb` | OpenAPI query schema (`FILTERS`) |
| `app/models/fleet_membership.rb` | `ransackable_attributes` (has `nickname`), `ransack_alias :username` |
| `app/frontend/frontend/components/Fleets/MembersFilterForm/index.vue` | Header search box, currently `usernameCont` |
| `app/frontend/frontend/components/Fleets/Squadrons/SquadronMembersFilterForm/index.vue` | Squadron roster search |
| `app/frontend/translations/*/placeholders.json` | Search placeholder text |
| `test/integration/api/v1/fleets_members_index_test.rb` | Existing `usernameCont` filter test |

## Not in scope (deferred)
- **Member pickers** — `FleetMemberSelect`, `SquadronMemberPicker`, `InventoryModal`, `InventoryItemModal`, `TransferModal` stay on `usernameCont` (see issue body). Becomes its own issue before the PR merges.
- **Admin fleet members** — admin has its own query and form; not what the issue is about.

## Discovery Log

- **2026-09-25** Initial research and plan creation. `nicknameCont` already exists on the API but nothing in the frontend sends it. Stats endpoints share the concern, so the new param filters stats too for free.
- **2026-09-25** Implemented. 31 request tests in the two index files and 19 in the stats/public members files pass; vitest, lint:ts, eslint and standardrb clean. No e2e spec touches either search box.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
