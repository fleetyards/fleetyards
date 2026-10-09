# Fleet dashboard: one request per data source

Working plan for #5549. Decisions live in the issue body. Deleted before the PR merges. Stacked on `feat/5541-fleet-dashboard-online-announcements-health`.

## Goal
A dashboard load, and every refetch on tab focus, sends one activity request and one calendar request, shared by the panels that read them.

## What changed

### Phase 1 — Activity limited per category
1. `Fleets::ActivityFeed#entries(per_category: true)` cuts each category to `limit` rather than the merged list, so one busy category cannot push another out of the page.
2. `GET /fleets/:slug/activity?perCategory=true`, with integration tests.

### Phase 2 — One activity query
1. The dashboard owns one `useFleetActivity` query with `perCategory`. It passes entries to `ActivityPanel` (its categories, minus those another panel shows), `InventoryPanel` and `NewMembersPanel`.
2. Those panels take their entries and loading state as props. The feed's "show more" raises the shared limit.

### Phase 3 — One calendar query
1. The dashboard owns one `useFleetCalendar` query over the union of the upcoming window (from yesterday to two weeks ahead) and the week on screen, whether that is the grid or the phone strip.
2. `UpcomingEventsPanel`, `WeekCalendarPanel` and `WeekStrip` take events as props. The week views report the week they show.

## Intent Verification

- [ ] **One request each**: a dashboard load sends exactly one `/activity` and one `/calendar` request, as seen in the network panel and asserted in a spec.
- [ ] **Panels unchanged**: each panel still hides when empty, and the feed still leaves out what another panel shows.
- [ ] **No crowding**: a fleet with 50 recent events still shows its inventory and member entries.

## Key files

| File | Role |
|------|------|
| `app/services/fleets/activity_feed.rb` | Feed merge and limits |
| `app/frontend/frontend/components/Fleets/Dashboard/index.vue` | Owns the shared queries |
| `app/frontend/frontend/components/Fleets/Dashboard/*Panel/index.vue` | Become presentational |

## Discovery Log

- **2026-10-10** Plan written from the code as it stands on #5544.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
