# Fleet dashboard: panels show that they are loading

Working plan for #5552. Decisions live in the issue body. Deleted before the PR merges. Stacked on `feat/5541-fleet-dashboard-online-announcements-health`.

## Goal
Every dashboard panel shows its own loading state, on the first answer and on refetches, and the dashboard links out for more instead of paging in place.

## What changed

### Phase 1 — Link out, ask for what is shown
1. `ActivityPanel` drops "show more" and asks for one page of 15. The `fleetDashboard.activity.showMore` key leaves all seven locales.
2. `InventoryPanel` reads 10 movements instead of 30.
3. `NewMembersPanel` links to the member list with `s=acceptedAt desc`: the roster's default order is by membership creation, not acceptance.

### Phase 2 — Loading states
1. Each panel renders on `isLoading || <has entries>` and passes `isFetching` as its loading state: activity, inventory, new members, upcoming events, contracts, action queue and online members.
2. `WeekStrip` shows its loading state and holds back the empty-day text until its week is answered. `CalendarGrid` takes a `loading` prop for the dashboard's compact week.
3. `DashboardPanel` leaves "empty" to the caller, so a refetch does not blank it; the inventory switch waits for the first answer that chooses its scope.

## Intent Verification

- [ ] **Loading shows**: on a throttled network, each panel stands in its place with its loading bar before its first answer, and the bar shows again on a tab-focus refetch.
- [ ] **No false empties**: the phone week strip does not say a day is empty while its week loads; the inventory panel's empty text and switch hold still through a refetch.
- [ ] **Links out**: the feed has no "show more"; "Show all" on new members opens the member list newest-joined first.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Fleets/Dashboard/*Panel/index.vue` | Each panel's query and loading state |
| `app/frontend/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue` | Shared panel frame, empty text |
| `app/frontend/frontend/components/Fleets/Events/CalendarGrid/index.vue` | `loading` prop |

## Discovery Log

- **2026-10-10** Panels passed `isLoading` to their frame but rendered only with entries, so the loading state could never show: hidden before the first answer, and `isLoading` stays false on a refetch.
- **2026-10-10** The member list's default sort is `created_at desc`, so the new members link needs `acceptedAt desc` to open on who joined last.

## Progress
- [x] Phase 1
- [x] Phase 2
