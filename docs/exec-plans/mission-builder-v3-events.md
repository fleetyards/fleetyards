# Mission Builder v3 — Events & Calendar Phase

Builds on the [Mission Builder v3 templates phase](mission-builder-v3.md). Templates already shipped; this plan adds **scheduled events** (concrete instances of a mission template with date/time, sign-ups, lifecycle) and a **fleet calendar**.

Scope is intentionally **Fleetyards-only** for this phase. Discord integration is a deliberate **Phase B**, not in this plan, but the data model and notification architecture are designed so Phase B drops in without touching event core code.

## Phasing

| Phase | Status | Includes |
|---|---|---|
| **A. Templates** | ✅ shipped | Missions, teams, ships, slots, archive lifecycle |
| **B. Events & Calendar** | 🔜 this plan | Scheduling, signups, fleet calendar, in-app notifications, iCal export |
| **C. Discord** | future | Webhook announcements, Discord scheduled-event sync, slash-command signup, edit-in-place messages |
| **D. Refinements** | future | Recurring events, after-action reports, fleet-to-fleet sharing, payout tracking |

## Concepts

| Term | Description |
|------|-------------|
| **Fleet Event** | Scheduled instance of a mission template (or ad-hoc). Has a date, status, sign-ups. |
| **Event Team / Ship / Slot** | Snapshot copies of the mission's structure at event creation. Editing the template later does not mutate spawned events. |
| **Event Sign-up** | A fleet member claiming a slot, optionally with a fleet vehicle commitment. |
| **Calendar** | Fleet-scoped month/week/list view of upcoming and past events. |

Snapshot semantics is non-negotiable — without it, editing a template would silently change every event built from it.

## Data Model

UUID PKs, integer `position` columns where ordering applies, all attached `cover_image` via ActiveStorage.

### `fleet_events`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `fleet_id` | uuid | FK, NOT NULL, indexed |
| `mission_id` | uuid | FK, nullable — null = ad-hoc event |
| `created_by_id` | uuid | NOT NULL |
| `title` | string | NOT NULL |
| `description` | text | |
| `slug` | string | NOT NULL, unique within fleet |
| `status` | string | NOT NULL, default `draft`. AASM column |
| `starts_at` | datetime | NOT NULL |
| `ends_at` | datetime | nullable |
| `timezone` | string | NOT NULL, default `UTC` — explicit so Phase C can convert for Discord without ambiguity |
| `location` | string | nullable — system/planet level (e.g. "Stanton — Crusader") |
| `meetup_location` | string | nullable — precise meetup (e.g. "Everus Harbor, hangar A-3") |
| `briefing` | text | nullable — markdown, objectives/route/payout |
| `visibility` | string | NOT NULL, default `members` — enum `members`/`officers`/`fleet` |
| `category` | integer | snapshot from mission |
| `scenario` | string | snapshot from mission |
| `cover_image_preset` | string | snapshot from mission |
| `archived_at` | datetime | soft delete |
| `external_uid` | uuid | NOT NULL — stable iCal UID; doubles as cross-system event identifier |
| `discord_event_id` | string | nullable — reserved for Phase C |
| `discord_message_id` | string | nullable — reserved for Phase C |
| `discord_synced_at` | datetime | nullable — reserved for Phase C |
| `created_at` / `updated_at` | datetime | |

`has_one_attached :cover_image`

**Indexes:** `(fleet_id, status)`, `(fleet_id, starts_at)`, unique `(fleet_id, slug)`, `(mission_id)`, unique `(external_uid)`

### `fleet_event_teams`, `fleet_event_ships`, `fleet_event_slots`

Mirror the mission structure exactly:

- `fleet_event_teams` belongs_to `fleet_event`, `source_team_id` (nullable)
- `fleet_event_ships` belongs_to `fleet_event_team`, `source_ship_id` (nullable), `model_id` (nullable, in_game enforced), filter columns (classification/focus/min_size/max_size/min_crew/min_cargo)
- `fleet_event_slots` polymorphic on `FleetEventTeam | FleetEventShip`, `source_slot_id` (nullable), `model_position_id` (nullable)

`source_*_id` is set when spawned from a mission, null when ad-hoc, and lets us trace event back to its template (useful for "events spawned from this mission" listing on the mission detail page).

### `fleet_event_signups`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `fleet_event_slot_id` | uuid | FK, NOT NULL |
| `fleet_membership_id` | uuid | FK, NOT NULL |
| `vehicle_id` | uuid | nullable — link to one of the member's `fleet_vehicles`; restricted to vehicles whose `model_id` satisfies the slot's filter (or matches `model_id` exactly) |
| `status` | string | NOT NULL, default `confirmed`. enum: `confirmed`, `tentative`, `withdrawn` |
| `notes` | text | nullable — short message ("running late, will arrive 8:15") |
| `confirmed_at` | datetime | |
| `withdrawn_at` | datetime | nullable |
| `created_at` / `updated_at` | datetime | |

**Indexes:** `(fleet_event_slot_id)`, `(fleet_membership_id)`, partial unique `(fleet_event_slot_id, fleet_membership_id) WHERE status != 'withdrawn'`

The partial unique index allows re-signup after withdrawal (history preserved as withdrawn rows).

## Lifecycle (AASM)

```
draft ──publish──▶ open ──lock──▶ locked ──start──▶ active ──complete──▶ completed
  │                  │              │                  │
  └──cancel──┐       └─cancel──┐    └─cancel──┐        └─cancel──┐
             ▼                ▼              ▼                  ▼
                            cancelled
```

- `draft` — only creator/admins see, can edit freely, no signups
- `open` — visible to fleet members, signups allowed, can be modified by admins
- `locked` — signups frozen, event imminent. Can revert to `open` by admin OR auto-locks at `starts_at - 1h` via scheduled job
- `active` — event in progress (UI shows "running")
- `completed` — finished, optional after-action notes
- `cancelled` — terminal, signups archived

Use the existing `AASM` gem (already a dep, used by `FleetMembership`).

## Privileges

Add to `FleetRole`:

```ruby
FleetEvent::AVAILABLE_PRIVILEGES = %w[
  fleet:events:read
  fleet:events:create
  fleet:events:update
  fleet:events:delete
  fleet:events:manage
].freeze

DEFAULT_PRIVILEGES = {
  admin: [],                           # gets manage via fleet:manage
  officer: ["fleet:events:manage"],
  member: ["fleet:events:read"]
}
```

Sign-up actions are gated on `fleet:events:read` (claim/withdraw your own) plus `fleet:events:manage` for admin overrides (kick someone from a slot).

## API Surface

### Events CRUD
- `GET    /api/v1/fleets/:slug/events?upcoming=true|false&q[…]`
- `POST   /api/v1/fleets/:slug/events` — ad-hoc create (no template)
- `GET    /api/v1/fleets/:slug/events/:event_slug`
- `PATCH  /api/v1/fleets/:slug/events/:event_slug`
- `DELETE /api/v1/fleets/:slug/events/:event_slug` — archive (soft); when already archived, hard-delete (mirrors mission delete pattern)

### Spawn from mission template
- `POST   /api/v1/fleets/:slug/missions/:mission_slug/events` — copy structure, accept overrides for title/starts_at/etc.

### State transitions
- `PUT    /api/v1/fleets/:slug/events/:event_slug/publish`  draft → open
- `PUT    /api/v1/fleets/:slug/events/:event_slug/lock`     open → locked
- `PUT    /api/v1/fleets/:slug/events/:event_slug/unlock`   locked → open
- `PUT    /api/v1/fleets/:slug/events/:event_slug/start`    locked|open → active
- `PUT    /api/v1/fleets/:slug/events/:event_slug/complete` active → completed
- `PUT    /api/v1/fleets/:slug/events/:event_slug/cancel`   any → cancelled

### Sign-ups
- `POST   /api/v1/fleet-event-slots/:id/signup` — member claims; body: `{ status, vehicle_id?, notes? }`
- `PATCH  /api/v1/fleet-event-slots/:id/signup` — update own signup (e.g. tentative → confirmed)
- `DELETE /api/v1/fleet-event-slots/:id/signup` — self-withdraw
- `DELETE /api/v1/fleet-event-signups/:id`     — admin removes (requires `fleet:events:manage`)

### Calendar
- `GET    /api/v1/fleets/:slug/calendar?from=YYYY-MM-DD&to=YYYY-MM-DD` — JSON, events keyed by date
- `GET    /api/v1/fleets/:slug/events.ics` — iCal feed for the fleet (private feed token in URL)
- `GET    /api/v1/fleets/:slug/events/:event_slug.ics` — single event iCal

## Vehicle binding on signup

When a member signs up to a slot, the API offers their **eligible fleet vehicles** — i.e. their `fleet_vehicles` whose `model_id`:

- equals the slot's `model_id` (strict match), OR
- satisfies the slot's filter (classification/focus/size range/crew/cargo)

Front-end: signup modal lists eligible vehicles as radio buttons, plus "I'll bring something" (vehicle_id: null). This is a real productivity win for fleets — you stop typing "I'll bring my Hammerhead" in Discord, the system already knows.

## Notification architecture (Phase B-ready)

This is the part that matters most for keeping Phase C clean.

### Event bus

Use `ActiveSupport::Notifications.instrument` as the dispatch primitive. AASM transitions and signup mutations publish:

- `fleet_event.published`
- `fleet_event.locked`
- `fleet_event.unlocked`
- `fleet_event.started`
- `fleet_event.completed`
- `fleet_event.cancelled`
- `fleet_event.starting_soon` (fired by scheduled job at `starts_at - 1h`)
- `fleet_event_signup.created`
- `fleet_event_signup.withdrawn`
- `fleet_event_signup.status_changed`

### Subscribers

Subscribers register at boot via an initializer. Phase B ships **one** subscriber:

- `Notifications::InApp::FleetEventSubscriber` — creates `Notification` records (existing model) for relevant fleet members

Phase C adds:

- `Notifications::Discord::FleetEventSubscriber` — POSTs to webhooks, syncs to Discord scheduled events, edits announcement messages

The dispatcher decoupling means **Phase C is purely additive** — no event core code changes.

### Per-fleet config (placeholder for Phase C)

Reserve a `fleet_notification_settings` table now (one row per fleet) so Phase C has a home for Discord webhook URLs, channel IDs, and per-event-type opt-outs:

```
fleet_notification_settings
  fleet_id (unique), discord_webhook_url (encrypted, nullable),
  discord_guild_id (nullable), discord_channel_id (nullable),
  enabled_in_app_events (jsonb array of event types — defaults to all),
  enabled_discord_events (jsonb array — defaults to empty until Phase C)
```

Phase B uses only `enabled_in_app_events`; Phase C populates the rest.

## Per-user notification prefs

Extend `notification_preferences` (table already exists for hangar/wishlist/etc.):

- `fleet_event_published`
- `fleet_event_starting_soon` (default ON for events you signed up to)
- `fleet_event_cancelled` (default ON for events you signed up to)
- `fleet_event_signup_changed` (event creators only — someone joined/left)

## Calendar UI

### Backend
- `GET /api/v1/fleets/:slug/calendar?from=&to=` returns events grouped by date in the fleet's timezone

### Frontend
- New page `pages/fleets/[slug]/calendar.vue` — month grid, click date → list of that day's events
- New page `pages/fleets/[slug]/events/index.vue` — list view (Upcoming / Past tabs), reuses `FilteredList`
- New page `pages/fleets/[slug]/events/[event].vue` — detail page with signup UI (mirrors mission detail layout)
- New components: `EventModal`, `EventPanel`, `EventSignupForm`, `CalendarGrid`
- Mission detail page gains a **"Spawn Event"** button (officer-gated) opening `EventModal` with starts_at picker, pre-filled from mission
- Mission detail page gains a **"Spawned events"** section showing recent events created from this template

For the calendar grid: prefer minimal in-house HTML/CSS month grid over a heavy library. SC fleets don't need Outlook-grade UX; click-day-to-see-events is enough for v1.

## Privileges in the UI

- Members: read events, claim/withdraw own signups
- Officers: full event CRUD, lifecycle transitions, kick signups
- Admins: same as officers (via `fleet:manage`)
- Event creator: always has CRUD on their own draft (even without manage privilege)

## Schema components (Rswag)

Mirror the mission components:
- `FleetEvent`, `FleetEventExtended`, `FleetEventsList`
- `FleetEventTeam`, `FleetEventShip`, `FleetEventSlot`
- `FleetEventSignup`, `FleetEventSignupOption` (slot's eligible vehicles for signup)
- `Inputs::FleetEventCreateInput`, `FleetEventUpdateInput`, `FleetEventSpawnInput` (override-fields when spawning from mission), `FleetEventSignupInput`

## Implementation order

1. **Migrations** — `fleet_events` + 4 child tables + `fleet_notification_settings`
2. **Models** — associations, AASM, snapshot copy logic in `FleetEvent.from_mission!(mission, attrs)`
3. **Privileges** — add to FleetRole, data migration to backfill existing roles
4. **Policies** — FleetEventPolicy, FleetEventSignupPolicy, scoped queries
5. **Controllers + routes** — CRUD + state transitions + signup + calendar + iCal
6. **JBuilder views** — base/show/index for each resource
7. **Schema components** — generate via `./bin/generate-schema`
8. **Request specs** — happy paths + auth checks for all endpoints (~30 specs estimated)
9. **Notification dispatcher + InApp subscriber** — fires from AASM callbacks
10. **Scheduled job** — `FleetEventStartingSoonJob`, runs every 5 min; fires `starting_soon` for events between now+55m and now+65m that haven't fired yet (track via `starting_soon_notified_at` column)
11. **iCal generation** — use `icalendar` gem (light dep) or hand-roll a small ICS builder; signed feed token per fleet
12. **Frontend** — pages, components, modals, calendar grid, signup flow, mission detail integration
13. **i18n** — labels/headlines/actions/messages for all event states + signup actions
14. **Seed task** — `bin/rails missions:seed_examples` extends to also create one upcoming event per category for the target fleet
15. **Manual UX QA** — create event, sign up as 2 members, transition through lifecycle, view calendar, export iCal

## Decisions baked in (call out if you disagree)

| Decision | Choice | Why |
|---|---|---|
| Snapshot vs live link | **Snapshot** | Editing template can't silently change spawned events |
| Status model | **AASM** (not enum) | Need transition guards + callback hooks for notifications |
| Sign-up model | **First-come, self-claim, self-withdraw** | Lowest friction; admins can override |
| Multi-slot per member | **No** — one signup per event | Avoids confusion; member can't be in two seats |
| Vehicle on signup | **Optional, validated against fleet_vehicles** | Reuses existing data; falls back to "I'll bring something" |
| Visibility levels | **`members` (default), `officers`, `fleet` (public to non-members)** | Most events are member-only; `fleet` enables public sign-ups for recruiting events |
| Ad-hoc events | **Allowed** — empty teams, just title + date | Quick "Friday meet" without template |
| Past events | **Visible by default** in Past tab; archived events hidden | Active history matters for fleet culture |
| Recurring events | **Phase D** — out of scope for B | Significant complexity, not core to MVP |
| Calendar UI | **In-house minimal grid** | SC fleets don't need FullCalendar; click-day pattern works |
| Calendar export | **iCal feed per fleet** (private token URL) | Universal — works in Apple Calendar, Google, Discord, Outlook |
| Signup notifications | **In-app via existing Notification model** | Reuses infrastructure; Discord layer added in Phase C |
| Discord readiness | **Reserved columns + subscriber pattern + notification_settings table** | Phase C is additive, no event core changes |

## Phase C preview (NOT in this plan, listed for future-proof context)

Designed-but-deferred for cleanliness now:

- **Discord webhook announcements** — when event opens, post embed to fleet's webhook channel; edit-in-place on state changes
- **Discord scheduled events** — sync Fleetyards events to native Discord scheduled events via Bot API; signups visible in Discord interest list
- **Slash command signup** — `/event signup <slug>` posts back to Discord with confirmation
- **@mentions on starting_soon** — ping signed-up members in their fleet channel
- **Two-way RSVP sync** — Discord interest = Fleetyards `tentative`; "I'm in" = `confirmed`

Hooks already in place after Phase B that Phase C uses without refactor:
- `discord_event_id`, `discord_message_id` columns on `fleet_events`
- `fleet_notification_settings.discord_webhook_url` etc.
- `Notifications::Discord::FleetEventSubscriber` slots into the existing event bus
- `external_uid` on events doubles as Discord scheduled-event correlation key

## Resolved decisions (locked-in answers to prior open questions)

| Topic | Decision |
|---|---|
| Public visibility for non-members | **Yes**, `visibility=fleet` enables public read + public signup (subject to slot privileges) |
| iCal token | **Rotatable** — fleet settings page exposes "Regenerate calendar feed URL"; old token immediately invalidated |
| Fleet default timezone | **Yes** — `fleets.default_timezone` (string, default `UTC`). Caveat: global fleets won't have a single right answer; users still see their browser-local time, fleet default is the canonical reference for the event card subtitle ("Fleet time: 21:00 UTC") |
| `max_attendees` | **Yes**, optional on events. Null = open-ended (no cap). Slot signups still tracked separately |
| Auto-lock | **Per-event opt-out** — boolean column `auto_lock_enabled` (default true), with `auto_lock_minutes_before` (default 60) |
| Reminder cadence | **`starting_soon` only (1h before)** for v1. User-configurable reminder schedules deferred to later |
| Spawning UX | **Dedicated new-event page** (`/fleets/:slug/events/new?from=:mission_slug`) — full form with markdown briefing field. Modal would cramp it |
| Event title default on spawn | **`{Mission title} — {readable date}`** (e.g. "Mining Operation — May 12, 2026") |
| Cancellation semantics | Signups **stay `confirmed`** (history preserved), no new signups allowed, **notification fired to all signed-up members** |
| Privilege model | No extra gating beyond `fleet:events:create` for spawn. (A separate "planner" role considered for later) |
| Test data | **Separate `events:seed_examples` rake task** — creates upcoming events for each category in the target fleet |
| Public visibility access control | Members get full slot detail; non-members on `visibility=fleet` events see title/time/location/category but NOT signup details — keeps recruiting public without exposing roster |
| Public signup | If a non-member tries to sign up to a `visibility=fleet` event, prompt to join the fleet first; or accept as a tentative interest and surface to officers as a recruiting lead (deferred to later) |

### Schema additions from the resolved decisions

`fleets`:
- `default_timezone` (string, default `UTC`)
- `calendar_feed_token` (string, indexed unique, generated on first calendar request, rotatable)

`fleet_events` (additions to base table above):
- `max_attendees` (integer, nullable — null = open-ended)
- `auto_lock_enabled` (boolean, NOT NULL, default `true`)
- `auto_lock_minutes_before` (integer, NOT NULL, default `60`)
- `cancelled_reason` (text, nullable — surfaced in cancellation notification)
5. **Reminders** — only `starting_soon` (1h before), or also a 24h-before reminder? Phase B does just 1h; can extend.
