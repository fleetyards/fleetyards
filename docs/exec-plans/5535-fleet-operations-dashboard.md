# Fleet start page: operations dashboard for members

Working plan for #5535. Decisions live in the issue body. Deleted before the PR merges.

## Goal
An accepted member opening `/fleets/:slug/` sees an operations dashboard: what changed lately, what is coming up, and what needs them. Each panel is gated by their role, the module's feature flag and the fleet subscription. Everyone else keeps today's introduction page.

## Open questions
- None blocking. The panel set and the activity source are decided in the issue body.

## What changed

### Phase 1 — Viewer signup on calendar entries
1. `FleetCalendarsController#show` preloads the current member's signups for the events in range (excluding withdrawn).
2. `fleet_calendars/show.jbuilder` adds `viewerSignup { status, occurrenceDate }` to each entry, matched on `occurrence_date` for recurring entries and on `nil` for one-off events.
3. Add the property to the hand-written calendar entry schema component, regenerate the schema and clients, and add an integration test.

### Phase 2 — `GET /fleets/:slug/activity`
1. `Fleets::ActivityFeed` query object. Each source is gated exactly as its own list endpoint gates it:
   - `member_joined`: accepted, not discarded memberships by `accepted_at`. Needs `fleet:members:read`.
   - `event_published` / `event_cancelled`: non-archived events by `published_at` / `cancelled_at`. Needs the mission-builder flag, the `events` subscription and `FleetEventPolicy#index?`, with the squadron narrowing for non-managers.
   - `contract_published` / `contract_claimed` / `contract_fulfilled`: the contracts' `visible_scope` rules. Needs the contracts flag and the `contracts` subscription.
   - `inventory_transfer_completed` / `inventory_item_added`: completed transfers and directly added items in inventories from `FleetInventoryPolicy`'s scope. Needs the logistics flag and the `logistics` subscription.
2. Each entry has `id`, `kind`, `category` (members/events/contracts/inventory), `occurredAt`, `involvesViewer`, `actor`, a `subject` (type/slug/title) and, for inventory entries, the `inventory`. `involvesViewer` is set when the viewer initiated or received the transfer, added the item, is its assigned member, or manages the inventory.
3. Params: `category`, `before` (cursor) and `limit` (default 20, max 50). Each source is limited before the merge, so no query loads a fleet's whole history.
4. Controller, route, jbuilder, schema components, and an openapi-ruby integration test with a role matrix.

### Phase 3 — Dashboard frontend
1. `useFleetDashboardAccess(fleet, membership)` decides which panels show and builds on `useFleetNavAccess`, `useFleetSubscription` and `useFeatures`.
2. `index.vue` splits in two: `FleetIntro` (today's page, unchanged for non-members) and `FleetDashboard` (accepted members).
3. Panels in `components/Fleets/Dashboard/`:
   - Compact header, kept on the page.
   - `AboutPanel`: description and squadron/team strips.
   - `ActivityPanel`
   - `UpcomingEventsPanel`: the calendar endpoint over the next 14 days, with `viewerSignup`.
   - `WeekCalendarPanel`: `CalendarGrid` in an embed mode with no URL sync and no create-on-click.
   - `ActionQueuePanel`: join requests, pending incoming transfers, squadron requests, and FID verification.
   - `ContractsPanel`: open contracts and `mine`.
   - `InventoryPanel`: activity filtered to `category=inventory`, with the viewer's own entries first.
   - `NewMembersPanel`: activity filtered to `category=members`.
4. Keep `data-tour` targets and the `fleet-guide` button.

### Phase 4 — Translations, tests, polish
1. Hand-written keys in all 7 locales.
2. Unit specs for the gating matrix and the panels, and an update to `index.spec.ts`.
3. Playwright: check that the fleet tour still works, and add a dashboard smoke test.

## Intent Verification

- [ ] **Members get the dashboard, others the intro**: a guest, a requested user and an accepted member each open the same fleet.
- [ ] **Role gating**: a plain member sees no action queue. An officer sees join requests. A role without contracts access gets no contracts panel and no request that would 403.
- [ ] **Recurring events show**: a weekly series that started last month appears in upcoming events and in the week calendar, with the viewer's signup status.
- [ ] **Activity respects visibility**: an officers-only inventory's items and squadron-restricted events never appear for a plain member.
- [ ] **Tour still works**: `FleetTour.spec.ts` passes.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/fleets/[slug]/index.vue` | Fleet start page, to be split into intro and dashboard |
| `app/frontend/frontend/composables/useFleetNavAccess.ts` | Existing per-module gates |
| `app/frontend/frontend/composables/useFleetSubscription.ts` | Subscription wall on the frontend |
| `app/frontend/frontend/components/Fleets/Events/CalendarGrid/index.vue` | Calendar, needs an embed mode |
| `app/controllers/api/v1/fleet_calendars_controller.rb` | Calendar entries, recurring occurrences expanded |
| `app/controllers/api/v1/fleet_contracts_controller.rb` | `visible_scope` rules to reuse |
| `app/policies/fleet_inventory_policy.rb` | Inventory visibility scope |
| `app/models/fleet_membership.rb` | `capabilities` |

## Not in scope (deferred)
- **Persisted activity log** — rejected for now (see issue). Revisit if the feed needs richer verbs, such as "role changed".
- **Tours and payouts panels** — not in the requested set. They can be added later through the same gating composable.

## Discovery Log

- **2026-10-09** Initial research and plan creation. The `upcoming=true` events filter drops recurring series that started in the past, so the calendar endpoint is the source for upcoming events. Event lists carry no viewer signup, which Phase 1 fixes.

- **2026-10-09** Service objects live in `app/services`; the feed is `Fleets::ActivityFeed`.
- **2026-10-09** Inventory items carry `entry_type` (deposit/withdrawal), so they appear as two kinds. Items that arrived with a transfer are left out, because the transfer entry already covers them.
- **2026-10-09** Squadron join requests are per squadron (one request each), so they are not in the action queue.
- **2026-10-09** Checked live on the dev dump. MERCCORP has no mission builder, and the events panels stay hidden there (its calendar answers 403). MARU shows all panels. At 390px the panels stack in urgency order with no horizontal scroll.
- **2026-10-09** In a fleet without events or contracts, "Latest updates" is mostly join entries, which repeat the New members panel.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4 (Playwright left to CI)
