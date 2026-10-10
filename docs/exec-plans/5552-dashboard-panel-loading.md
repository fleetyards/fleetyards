# Fleet dashboard: panels show that they are loading

Working plan for #5552. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every dashboard panel shows its own loading state, on the first answer and on refetches, and the dashboard links out for more instead of paging in place.

## What changed

### Phase 1 — Link out, ask for what is shown
1. `ActivityPanel` drops "show more" and asks for one page of 15. The `fleetDashboard.activity.showMore` key leaves all seven locales.
2. `InventoryPanel` keeps reading 30 movements: "mine" is picked out of that page on the client, and a shallower page left it empty in a busy fleet.
3. `NewMembersPanel` links to the member list with `s=acceptedAt desc`: the roster's default order is by membership creation, not acceptance.

### Phase 2 — Loading states
1. `DashboardPanel` takes `pending`, `fetching`, `failed` and `empty`, and owns the rule: blank while pending, the failure note when an ask failed with nothing to show, the `empty` slot once answered empty, and the bar on any fetch.
2. Every panel always stands for a reader who may see it, with an empty state of its own (`DashboardEmpty`: icon, title, hint, optional action). `GetStartedPanel` is gone: its prompts are the empty states of upcoming events and contracts.
3. The online panel shows no count before its first answer and keeps presence-driven refetches out of the bar; the feed keeps its old page while `exclude` changes.
4. `WeekStrip` says nothing about a day until its week is answered, and says it failed rather than that the day is free. The compact week grid counts as loading until it has a range.

## Intent Verification

- [ ] **Loading shows**: on a throttled network, each panel stands in its place with its loading bar before its first answer, and the bar shows again on a tab-focus refetch.
- [ ] **Useful empty states**: every panel stays put after an empty answer and says what would show up there; events and contracts offer to start one to whoever may.
- [ ] **No false empties**: the phone week strip does not say a day is empty while its week loads; the inventory panel's empty text and switch hold still through a refetch.
- [ ] **Links out**: the feed has no "show more"; "Show all" on new members opens the member list newest-joined first.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Fleets/Dashboard/*Panel/index.vue` | Each panel's query and loading state |
| `app/frontend/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue` | Shared panel frame: pending, failed and empty states |
| `app/frontend/frontend/components/Fleets/Dashboard/DashboardEmpty/index.vue` | A panel's empty state |
| `app/frontend/frontend/components/Fleets/Events/CalendarGrid/index.vue` | `loading` prop |

## Discovery Log

- **2026-10-10** Panels passed `isLoading` to their frame but rendered only with entries, so the loading state could never show: hidden before the first answer, and `isLoading` stays false on a refetch.
- **2026-10-10** The member list's default sort is `created_at desc`, so the new members link needs `acceptedAt desc` to open on who joined last.

- **2026-10-10** Hiding empty panels made the page jump when an answer came back empty, and the first-load shells contradicted it. Panels now always stand with an empty state.
- **2026-10-10** The query client keeps the previous answer across a key change for every query (`plugins/QueryClient.ts`), and TanStack reports a failed refetch as an error while keeping its data. A panel calls itself failed only on `isError && !data`, and the week views treat a placeholder as unanswered.

## Progress
- [x] Phase 1
- [x] Phase 2
