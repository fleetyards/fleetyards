# Fleet dashboard: online members and announcements

Working plan for #5541. Decisions live in the issue body. Deleted before the PR merges. Stacked on `feat/5535-fleet-operations-dashboard`.

## Goal
Two more panels on the members' dashboard: who is online (friends first), and announcements that officers pin.

## What changed

### Phase 1 — Announcements backend
1. Migration and `FleetAnnouncement` model: fleet, author, body, optional `expires_at`, and an `active` scope.
2. Privilege group `announcements` (`fleet:announcements:manage`), included in the admin and officer presets, plus a `manage_announcements` capability. A data migration grants it to existing roles that hold `fleet:memberships:manage`, the same rule payouts used.
3. Policy, controller (index/create/update/destroy), routes, jbuilder views, schema components and integration tests.

### Phase 2 — Online endpoint
1. `GET /fleets/:slug/online-members`: reads `UserPresence`, respects `show_online_status`, lists friends first, and is gated like the member list.

### Phase 3 — Frontend
1. `OnlineMembersPanel`, refreshed every minute.
2. `AnnouncementsPanel` above the main column, plus a modal to post and edit announcements. Expiry is chosen as a duration, so no datetime picker is involved. The post button sits in `#header-right` for managers.
3. Labels for the new privilege group in all 7 locales, and dashboard strings in `fleetDashboard.json`.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_role.rb` | `PRIVILEGE_GROUPS` and presets |
| `app/models/fleet_membership.rb` | `CAPABILITY_PRIVILEGES` |
| `app/lib/user_presence.rb` | Online set |
| `db/data/20260912101000_grant_payout_privileges_to_existing_roles.rb` | Backfill precedent |
| `app/frontend/frontend/components/Fleets/Dashboard/` | Panels |

## Not in scope (deferred)
- **Notifying members of a new announcement** (in-app or Discord) — it reuses the notification pipeline and becomes its own issue.

## Discovery Log

- **2026-10-09** The member health check moved to its own page (#5543). The endpoint and panel built here were removed.

- **2026-10-09** Presence respects `show_online_status`. `last_active_at` is written at most every 15 minutes by `Api::BaseController#set_last_active_at`. Role presets only apply to new fleets, so a new privilege group needs a backfill.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
