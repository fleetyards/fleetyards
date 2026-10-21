# Homepage: a landing page for visitors and a personal dashboard for pilots

Working plan for #5865. Decisions live in the issue body. Deleted before the PR merges.

Mockups: the Claude Design canvas linked from the issue, built from the app's own markup.

## Goal

`/` shows signed-out visitors a landing page that explains Fleetyards and shows live data, and signed-in pilots a dashboard of their own fleets, events, hangar and patch changes.

## Open questions

- None blocking. Draft and officers-only fleet events are left out of `/me/events` (see Phase 2); the fleet calendar itself is unchanged.

## What changed

### Phase 1 — Game events (backend + admin)
1. `GameEvent` model: title, description, location, starts_at, ends_at, category (mission category enum values), link, published, cover image. uuid id. Validation: ends_at >= starts_at.
2. Admin CRUD under `admin/api/v1/game-events` with a new `game_events` privilege (system group) and its label in every locale.
3. Public `GET /game-events` (published, upcoming or running, paginated).
4. Admin pages under `/game-events` (list, create, edit) following funding goals.

### Phase 2 — Personal endpoints
1. Extract the per-fleet calendar entry building out of `FleetCalendarsController#show` into a shared service.
2. `GET /me/events`: every accepted fleet's calendar (same gates as the fleet calendar, minus drafts and officers-only events for non-managers) merged with published game events, sorted by start.
3. `GET /me/fleets`: per fleet — role, online count, latest active announcement, pending join requests and transfers, each gated by the member's capabilities.
4. `GET /me/patch-changes`: the current build's model changes, narrowed to models in the user's hangar or wishlist, with whether the model is owned or wished.
5. Quick stats gain `fleetsCount`; bump the cache key.

### Phase 3 — Shared dashboard shell
1. Move `DashboardPanel`, `DashboardEmpty` and `liveQuery` out of `Fleets/Dashboard` into `shared/components/Dashboard/`; neutral `dashboard.*` translation keys; fleet dashboard imports the shared ones.

### Phase 4 — Landing page (signed out)
1. `pages/index.vue` branches on `isAuthenticated` (and the rollout flag), rendering `Home/Landing` or `Home/Dashboard`; the current page stays as the fallback while the flag is off.
2. Landing sections: hero (pills, title, lede, search, actions), stat tiles, feature panels, this patch, in-game events, latest ships, sign-up panel.
3. Fix the search field's accessible label (`home.search`) and the search button's label.

### Phase 5 — Dashboard (signed in)
1. Panels: patch, invites alert, coming up (with RSVP), my fleets, your ships in this patch, hangar, notifications, friends online. Each owns its query and loading state; phone order by urgency.

### Phase 5b — Patch loading screens
1. The export uploads `loadingscreen*.png` (one or more) at the root of each version folder. `loading_screens` holds one row per image (version, environment, name, bucket ETag) with the image attached.
2. `ScData::LoadingScreensImportJob` (daily, 22:45) attaches them for every configured or recorded build, skips an unchanged ETag, and drops rows of builds nothing knows about any more.
3. `/sc-data/builds` items gain `loadingScreens`; the item is its own `ScDataBuild` component now.
4. The patch panel draws one of the live build's screens per visit, falling back to the hangar art.

### Phase 6 — Translations, tests, review
1. All new keys in all 7 locales.
2. Model, policy, integration (openapi) tests; component specs for the new panels.

## Intent Verification

- [ ] Signed out, `/` shows the landing page with live numbers, the current build and published game events.
- [ ] Signed in, `/` shows the dashboard; every panel shows its own loading state and links to its full page.
- [ ] `/me/events` returns only events the user could open in their fleet calendar, plus published game events, sorted by start.
- [ ] An admin with the `game_events` privilege can create, edit and delete game events; one without it gets 403.
- [ ] The homepage search has a real accessible label in every locale.

## Key files

| File | Role |
|------|------|
| `app/models/funding_goal.rb`, `app/controllers/admin/api/v1/funding_goals_controller.rb` | Template for the admin-curated model |
| `app/controllers/api/v1/fleet_calendars_controller.rb` | Calendar entry building to extract |
| `app/controllers/api/v1/me/calendar_subscriptions_controller.rb` | `/me` controller pattern |
| `app/controllers/api/v1/stats/base_controller.rb` | Patch changes and quick stats |
| `app/frontend/frontend/components/Fleets/Dashboard/` | Panel pattern and shell to share |
| `app/frontend/frontend/pages/index.vue` | Current homepage |

## Not in scope (deferred)

- None.

## Discovery Log

- **2026-10-20** Initial research and plan creation.
- **2026-10-20** The fleet calendar does not filter drafts or officers-only events for plain members; `/me/events` filters them itself rather than changing the calendar here.
- **2026-10-21** The export now carries loading screens per build (3840×2160 PNGs, 10–15 MB, multipart ETags so no MD5 to compare); they are imported rather than parsed, so the parsed tree is untouched.
- **2026-10-20** `FormInput` builds its aria-label from `labels.<translationKey>` even with `no-label`; `labels.search.default` does not exist, `labels.home.search` does.

## Progress

- [ ] Phase 1 — Game events
- [ ] Phase 2 — Personal endpoints
- [ ] Phase 3 — Shared dashboard shell
- [ ] Phase 4 — Landing page
- [ ] Phase 5 — Dashboard
- [ ] Phase 6 — Translations, tests, review
