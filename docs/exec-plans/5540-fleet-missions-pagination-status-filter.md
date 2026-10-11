# Fleet missions list stops at 30 and cannot filter by status

Working plan for #5540. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every mission a member may see is reachable from the missions page, and the event template picker lists published missions from the server, paged and searchable.

## What changed

### Phase 1 — API
1. `MissionQuery` component: `titleCont`, `statusEq` (`MissionStatusEnum`), `s` (`MissionSortEnum` from `Mission::ALLOWED_SORTING_PARAMS`).
2. Index declares `PageParameter`, `perPage` and `q` next to `archived`; controller permits `status_eq`.
3. Tests for paging, `perPage`, `statusEq` and `titleCont`; regenerate schema and clients.

### Phase 2 — Missions page
1. Send `page`, `perPage` and `q[s]` (the table's sort links already write `s`), render `Paginator` top and bottom.
2. Switching between the active and archived tabs returns to page one.

### Phase 3 — Template picker
1. Ask for `q[statusEq]=published` and drop the client-side draft filter.
2. Title search and a local page (prev / next) inside the modal — the route-bound `Paginator` would page the events list behind it.
3. Empty state: with no published mission and no search, a one-row probe without the status filter tells "none published yet" apart from "no missions".
4. New label in all seven locales.

## Intent Verification

- [ ] **Past 30** — a fleet with 31 missions reaches the 31st on page 2 of the missions page.
- [ ] **Picker shows published only, from the server** — drafts never take a slot.
- [ ] **Picker reaches every published mission** — via search or paging.
- [ ] **Empty states** — all-drafts fleet is told none is published; no-missions fleet is told it has none.

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/missions_controller.rb` | index |
| `test/integration/api/v1/fleets_missions_index_test.rb` | OpenAPI block + tests |
| `app/api_components/v1/schemas/queries/mission_query.rb` | new query component |
| `app/frontend/frontend/pages/fleets/[slug]/missions/index.vue` | missions page |
| `app/frontend/frontend/components/Fleets/Events/MissionTemplatePicker/index.vue` | picker |

## Discovery Log

- **2026-10-11** The controller already paginated and permitted `q[title_cont]`/`q[s]`; only the schema refused them. The table's sortable columns wrote `?s=` which the page never sent, so sorting did nothing either.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
