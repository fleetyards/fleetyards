# Blueprint wishlist and personal mission list

Working plan for #5876. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A blueprint can be wanted as well as owned, `/hangar/blueprints` shows Owned / Wanted / Missions tabs, and the Missions tab is generated from the wanted blueprints.

## Open questions
- None.

## What changed

### PR 1 — Wishlist
1. Migration: `user_blueprints.wanted boolean, null: false, default: false`. Existing rows stay owned.
2. `UserBlueprint` scopes `owned` / `wanted`. Every path that reads a row as "owned" filters `wanted: false`: `Blueprint.owned_by` / `not_owned_by`, `BlueprintFiltersConcern#owned_ids_for`, `FleetBlueprintsController#owners_for`.
3. `Blueprint.wanted_by` scope; `wanted` query param in `BlueprintFiltersConcern` (permitted, pulled out of ransack like `owned`); `wanted` boolean on the blueprint jbuilder partial and `show.jbuilder`, via `@wanted_blueprint_ids`.
4. Routes `put :want` / `delete :want, action: :unwant`. `own` upserts and clears `wanted` (want → have); `unown` only deletes owned rows, `unwant` only wanted ones. Policy alias to `own?`.
5. Fleet: `wanted` param on `/fleets/:slug/blueprints` switching the join to wanted rows; same `fleet:blueprints:read` + `blueprints_filter_all` gate.
6. API components: `wanted` on shared `blueprint.rb` and `blueprint_query.rb`; fleet query param. Integration tests (path docs for `want`), regenerate schema + orval.
7. Frontend: a `WantToggle` beside `OwnToggle` (hidden when owned) on the row and the detail page; invalidates the same keys.
8. `/hangar/blueprints` (`hangar-blueprints`): `useBlueprints` with `owned=true` or `wanted=true`, tabs via a `?tab=` composable like `useLedgerTab`. Hangar index button + `PledgeItemsSwitch` entry, route name union, routes spec.
9. Fleet blueprints page: Owned / Wanted tabs.
10. Locales in all 7: `actions.blueprint.want/unwant`, `messages.error.blueprint.want`, `labels.filters.blueprints.wanted`, `nav.hangar.blueprints`, `title.hangar.blueprints`, tab labels.

### PR 2 — Missions tab
1. `GameMission` scope rewarding any of a set of blueprints (inverse of `GameMission#blueprints`: wanted blueprint → current build's `BlueprintSource.pool_sc_ref` → `blueprint_pool_refs &&`), restricted to `released`.
2. `rewardsWantedBlueprints` (name TBD) param on the missions index, current user only; each mission carries the wanted blueprints it rewards.
3. Missions tab on `/hangar/blueprints` reusing the mission row, with the matched blueprints listed per row.

## Intent Verification

- [ ] **Want toggle** — a blueprint row and page offer "Want"; it disappears once owned
- [ ] **Want → have** — owning a wanted blueprint moves it from the Wanted to the Owned tab
- [ ] **Hangar tabs** — `/hangar/blueprints` shows Owned and Wanted, `?tab=` survives reload
- [ ] **Fleet** — a member with `fleet:blueprints:read` sees others' wanted blueprints; a member with `blueprints_filter: hide` shares neither
- [ ] **Owned unaffected** — owned counts, owned filter and fleet owners never include wanted rows
- [ ] **Missions tab** — lists exactly the released missions rewarding a wanted blueprint; wanting/owning updates it

## Key files

| File | Role |
|------|------|
| `app/models/user_blueprint.rb` | the marker; gains `wanted` |
| `app/models/blueprint.rb` | `owned_by` / `not_owned_by` scopes |
| `app/controllers/concerns/blueprint_filters_concern.rb` | `owned` filter, `owned_ids_for` |
| `app/controllers/api/v1/blueprints_controller.rb` | `own` / `unown` |
| `app/controllers/api/v1/fleet_blueprints_controller.rb` | fleet join, `owners_for` |
| `app/views/api/v1/blueprints/_blueprint.jbuilder`, `show.jbuilder` | `owned` field |
| `app/api_components/shared/v1/schemas/blueprint.rb`, `v1/schemas/queries/blueprint_query.rb` | hand-written schema |
| `test/integration/api/v1/blueprints_own_test.rb` | path docs for own/unown |
| `app/frontend/frontend/components/Blueprints/OwnToggle` | toggle pattern |
| `app/frontend/frontend/pages/hangar/routes.ts`, `index.vue`, `components/Hangar/PledgeItemsSwitch` | hangar registration |
| `app/frontend/frontend/pages/hangar/inventories/index.vue`, `composables/useLedgerTab.ts` | segmented tab pattern |
| `app/frontend/frontend/pages/fleets/[slug]/blueprints.vue` | fleet list |
| `app/models/game_mission.rb` | `blueprint_pool_refs`, `#blueprints` |

## Not in scope (deferred)
- **Per-mission tracking (done flags, manual list)** — rejected in the issue; the list is generated.

## Discovery Log

- **2026-10-21** Initial research and plan creation. Every owned path treats any `UserBlueprint` row as owned, so the `wanted` column must be filtered in four places, not one. `useFilters` keeps `tab` out of `q`, so `?tab=` is safe.

## Progress
- [ ] PR 1 — Wishlist
- [ ] PR 2 — Missions tab
