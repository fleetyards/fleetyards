# Mission Builder

A fleet tool for creating reusable mission templates with ship/role requirements, spawning scheduled events from those templates, and optionally announcing events to connected Discord servers via webhooks.

## Terminology

| Term | Description |
|------|-------------|
| **Mission** | A reusable template owned by a fleet. Defines required ship slots, roles, and objectives. |
| **Mission Slot** | A single position within a mission specifying what kind of ship/crew is needed. |
| **Fleet Event** | A concrete, scheduled instance of a mission with a date/time, sign-ups, and status. |
| **Event Sign-up** | A fleet member claiming a slot in an event with one of their fleet vehicles. |
| **Discord Webhook** | A fleet-configured outgoing webhook URL for pushing event announcements. |

## SC Data Available for Mission Slots

The following ship attributes from the Model table are useful for defining mission requirements:

| Attribute | Column | Type | Example Values |
|-----------|--------|------|----------------|
| Classification | `classification` | string | Combat, Industrial, Multi-Role, Exploration, Transporter, Support |
| Focus | `focus` | string | Light Freight, Mining, Bounty Hunting, Medical, Salvage, Pathfinder |
| Size | `size` | string | snub, small, medium, large, extra_large, capital |
| Min Crew | `min_crew` | integer | 1, 2, 3, 6 |
| Max Crew | `max_crew` | integer | 1, 4, 8, 28 |
| Cargo (SCU) | `cargo` | decimal | 0, 46, 576, 9600 |
| SCM Speed | `scm_speed` | decimal | m/s |
| Ground vehicle | `ground` | boolean | true/false |
| Manufacturer | via `manufacturer_id` | relation | RSI, Drake, MISC, Aegis |

**Career/Role from SC data** (parsed but stored as `classification`/`focus` on Model):
- `vehicleCareer`: Combat, Transporter, Multi-Role, Exploration, Industrial
- `vehicleRole`: Light Fighter, Medium Freight, Heavy Bomber, Drop Ship, Corvette, Mining, Salvage

This data lets mission creators define slots like "need a medium+ cargo ship with 46+ SCU" or "need a combat fighter, small size" — the system filters the fleet's available ships against slot criteria.

## Data Model

### missions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `fleet_id` | uuid | FK, NOT NULL, indexed | Owning fleet |
| `created_by` | uuid | NOT NULL | User who created it |
| `title` | string | NOT NULL | Mission name |
| `description` | text | | Rich-text description / briefing |
| `classification` | string | | Filter: mission type (combat, cargo_run, mining_op, exploration, mixed) |
| `min_members` | integer | | Minimum fleet members needed |
| `max_members` | integer | | Maximum fleet members allowed |
| `estimated_duration_minutes` | integer | | Estimated time to complete |
| `slug` | string | NOT NULL, unique(fleet_id) | URL-friendly identifier |
| `archived_at` | datetime | | Soft-archive timestamp |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

**Indexes:** `(fleet_id)`, `(fleet_id, slug)` unique

### mission_slots

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `mission_id` | uuid | FK, NOT NULL, indexed | Parent mission |
| `title` | string | NOT NULL | Slot label (e.g. "Escort Fighter 1", "Cargo Hauler") |
| `description` | text | | What this slot does in the mission |
| `required` | boolean | NOT NULL, default: true | Must be filled before event starts? |
| `quantity` | integer | NOT NULL, default: 1 | How many of this slot type needed |
| `model_id` | uuid | FK, nullable | Specific ship model required (exact match) |
| `classification` | string | | Required ship classification (Combat, Industrial, etc.) |
| `focus` | string | | Required ship focus (Mining, Salvage, etc.) |
| `min_size` | string | | Minimum ship size (snub, small, medium, large, etc.) |
| `max_size` | string | | Maximum ship size |
| `min_crew` | integer | | Minimum crew capacity required |
| `min_cargo` | decimal | | Minimum cargo SCU required |
| `position` | integer | NOT NULL | Sort order |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

**Indexes:** `(mission_id)`, `(mission_id, position)`

### fleet_events

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `fleet_id` | uuid | FK, NOT NULL, indexed | Owning fleet |
| `mission_id` | uuid | FK, nullable | Source mission template (null = ad-hoc event) |
| `created_by` | uuid | NOT NULL | User who scheduled it |
| `title` | string | NOT NULL | Event title (defaults from mission) |
| `description` | text | | Event briefing (defaults from mission) |
| `status` | string | NOT NULL, default: "draft" | AASM: draft, open, locked, active, completed, cancelled |
| `starts_at` | datetime | | Scheduled start |
| `ends_at` | datetime | | Scheduled/estimated end |
| `notify_discord` | boolean | NOT NULL, default: true | Send Discord webhook for this event? |
| `discord_message_id` | string | | Tracked Discord message for updates |
| `slug` | string | NOT NULL, unique(fleet_id) | URL-friendly identifier |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

**Indexes:** `(fleet_id)`, `(fleet_id, slug)` unique, `(fleet_id, status)`, `(mission_id)`

**AASM States:**
- `draft` → only visible to event creator / admins
- `open` → members can sign up for slots
- `locked` → sign-ups closed, event about to start
- `active` → event in progress
- `completed` → event finished
- `cancelled` → event was cancelled

**Transitions:**
- `draft` → `open` (publish)
- `open` → `locked` (lock_signups)
- `open` → `cancelled` (cancel)
- `locked` → `active` (start)
- `locked` → `open` (reopen)
- `locked` → `cancelled` (cancel)
- `active` → `completed` (complete)
- `active` → `cancelled` (cancel)

### event_slots

Copies from `mission_slots` when event is created from mission, but can also be created ad-hoc.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `fleet_event_id` | uuid | FK, NOT NULL, indexed | Parent event |
| `mission_slot_id` | uuid | FK, nullable | Source mission slot (if from template) |
| `title` | string | NOT NULL | Slot label |
| `description` | text | | |
| `required` | boolean | NOT NULL, default: true | |
| `quantity` | integer | NOT NULL, default: 1 | |
| `model_id` | uuid | FK, nullable | Specific ship model |
| `classification` | string | | |
| `focus` | string | | |
| `min_size` | string | | |
| `max_size` | string | | |
| `min_crew` | integer | | |
| `min_cargo` | decimal | | |
| `position` | integer | NOT NULL | Sort order |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

**Indexes:** `(fleet_event_id)`, `(fleet_event_id, position)`

### event_sign_ups

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `event_slot_id` | uuid | FK, NOT NULL, indexed | Which slot |
| `fleet_membership_id` | uuid | FK, NOT NULL, indexed | Which fleet member |
| `vehicle_id` | uuid | FK, nullable | Which of their fleet vehicles (null = "I'll bring something") |
| `status` | string | NOT NULL, default: "confirmed" | confirmed, tentative, withdrawn |
| `confirmed_at` | datetime | | |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

**Indexes:** `(event_slot_id)`, `(fleet_membership_id)`, `(event_slot_id, fleet_membership_id)` unique

### fleet_discord_webhooks

Per-fleet Discord webhook configuration for event announcements.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `fleet_id` | uuid | FK, NOT NULL, indexed | Owning fleet |
| `name` | string | NOT NULL | Label (e.g. "Events Channel", "Announcements") |
| `webhook_url` | string | NOT NULL | Discord webhook URL (encrypted) |
| `active` | boolean | NOT NULL, default: true | Enable/disable without deleting |
| `event_types` | string[] | NOT NULL, default: [] | Which event state changes trigger posts (opened, locked, started, completed, cancelled) |
| `created_at` | datetime | | |
| `updated_at` | datetime | | |

**Indexes:** `(fleet_id)`

## Privilege System

Following the existing pattern, add privileges to the role system:

```ruby
# Mission model
Mission::AVAILABLE_PRIVILEGES = [
  "fleet:missions:read",
  "fleet:missions:create",
  "fleet:missions:update",
  "fleet:missions:delete",
  "fleet:missions:manage"
]

# FleetEvent model
FleetEvent::AVAILABLE_PRIVILEGES = [
  "fleet:events:read",
  "fleet:events:create",
  "fleet:events:update",
  "fleet:events:delete",
  "fleet:events:manage"
]

# FleetDiscordWebhook model
FleetDiscordWebhook::AVAILABLE_PRIVILEGES = [
  "fleet:discord_webhooks:read",
  "fleet:discord_webhooks:create",
  "fleet:discord_webhooks:update",
  "fleet:discord_webhooks:delete",
  "fleet:discord_webhooks:manage"
]
```

**Default role assignments:**
- Admin: `fleet:missions:manage`, `fleet:events:manage`, `fleet:discord_webhooks:manage`
- Officer: `fleet:missions:read`, `fleet:events:read`, `fleet:events:create`, `fleet:events:update`
- Member: `fleet:missions:read`, `fleet:events:read`

Sign-up privileges are implicit: any accepted member can sign up for open events.

## API Endpoints

### Missions (templates)

| Method | Path | Action | Privilege |
|--------|------|--------|-----------|
| GET | `/fleets/:fleet_slug/missions` | List missions | `fleet:missions:read` |
| GET | `/fleets/:fleet_slug/missions/:slug` | Show mission + slots | `fleet:missions:read` |
| POST | `/fleets/:fleet_slug/missions` | Create mission | `fleet:missions:create` |
| PUT | `/fleets/:fleet_slug/missions/:slug` | Update mission | `fleet:missions:update` |
| DELETE | `/fleets/:fleet_slug/missions/:slug` | Archive mission | `fleet:missions:delete` |

Missions accept nested `mission_slots_attributes` for slot CRUD.

### Fleet Events

| Method | Path | Action | Privilege |
|--------|------|--------|-----------|
| GET | `/fleets/:fleet_slug/events` | List events (filterable by status) | `fleet:events:read` |
| GET | `/fleets/:fleet_slug/events/:slug` | Show event + slots + sign-ups | `fleet:events:read` |
| POST | `/fleets/:fleet_slug/events` | Create event (optionally from mission) | `fleet:events:create` |
| PUT | `/fleets/:fleet_slug/events/:slug` | Update event details | `fleet:events:update` |
| DELETE | `/fleets/:fleet_slug/events/:slug` | Cancel event | `fleet:events:delete` |
| PUT | `/fleets/:fleet_slug/events/:slug/publish` | draft → open | `fleet:events:update` |
| PUT | `/fleets/:fleet_slug/events/:slug/lock` | open → locked | `fleet:events:update` |
| PUT | `/fleets/:fleet_slug/events/:slug/reopen` | locked → open | `fleet:events:update` |
| PUT | `/fleets/:fleet_slug/events/:slug/start` | locked → active | `fleet:events:update` |
| PUT | `/fleets/:fleet_slug/events/:slug/complete` | active → completed | `fleet:events:update` |
| PUT | `/fleets/:fleet_slug/events/:slug/cancel` | any → cancelled | `fleet:events:update` |

### Event Sign-ups

| Method | Path | Action | Auth |
|--------|------|--------|------|
| POST | `/fleets/:fleet_slug/events/:slug/sign-ups` | Sign up for a slot | any member |
| PUT | `/fleets/:fleet_slug/events/:slug/sign-ups/:id` | Update sign-up (change vehicle/status) | own sign-up |
| DELETE | `/fleets/:fleet_slug/events/:slug/sign-ups/:id` | Withdraw from slot | own sign-up or `fleet:events:manage` |

### Fleet Discord Webhooks

| Method | Path | Action | Privilege |
|--------|------|--------|-----------|
| GET | `/fleets/:fleet_slug/discord-webhooks` | List webhooks | `fleet:discord_webhooks:read` |
| POST | `/fleets/:fleet_slug/discord-webhooks` | Create webhook | `fleet:discord_webhooks:create` |
| PUT | `/fleets/:fleet_slug/discord-webhooks/:id` | Update webhook | `fleet:discord_webhooks:update` |
| DELETE | `/fleets/:fleet_slug/discord-webhooks/:id` | Delete webhook | `fleet:discord_webhooks:delete` |
| POST | `/fleets/:fleet_slug/discord-webhooks/:id/test` | Send test message | `fleet:discord_webhooks:manage` |

## ActionCable Channels

### FleetEventsChannel

Real-time updates for fleet events. Broadcasts when:
- Event status changes (published, locked, started, completed, cancelled)
- New sign-ups or withdrawals
- Event details updated

Stream: `fleet_events:#{fleet.id}` — all accepted fleet members subscribe.

## Discord Integration

### Webhook Flow

1. Fleet admin configures a Discord webhook URL in fleet settings
2. When a fleet event transitions state (and matches configured `event_types`), a background job fires
3. The job builds a Discord embed and POSTs it via the `discordrb-webhooks` gem (already in Gemfile)
4. For the initial "open" post, the `discord_message_id` is stored on the event
5. Subsequent state changes edit the existing Discord message (PATCH) to keep one authoritative post

### Discord Embed Format

```
[Fleet Logo] Fleet Name — Event Announcement
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Title: Operation Stardust
📝 Description: Mining escort run through Pyro...
📅 Starts: 2026-04-25 20:00 UTC
⏱️ Duration: ~2 hours
🔵 Status: OPEN — Sign up now!

Slots:
├── ✅ Escort Fighter (2/3) — Combat, Small+
├── ✅ Cargo Hauler (1/2) — Transporter, 96+ SCU
└── ⬜ Scout (0/1) — Exploration, any size

[Sign Up on FleetYards →]
```

### Background Job

`Discord::FleetEventNotificationJob`:
- Receives `fleet_event_id` and `transition` (opened, locked, started, completed, cancelled)
- Loads all active webhooks for the fleet where `event_types` includes the transition
- Builds embed, POSTs or PATCHes Discord message
- Stores/updates `discord_message_id` on the event
- Retries with exponential backoff on Discord rate limits (429)

## Vehicle Matching Logic

When a member signs up for a slot, the system validates their chosen vehicle against the slot's criteria:

```ruby
class EventSlot
  def matching_vehicles(fleet_membership)
    scope = fleet_membership.fleet.fleet_vehicles
      .joins(vehicle: :model)
      .where(vehicle: { user_id: fleet_membership.user_id })

    scope = scope.where(models: { id: model_id }) if model_id.present?
    scope = scope.where(models: { classification: classification }) if classification.present?
    scope = scope.where(models: { focus: focus }) if focus.present?
    scope = scope.where("models.cargo >= ?", min_cargo) if min_cargo.present?
    scope = scope.where("models.min_crew >= ?", min_crew) if min_crew.present?

    if min_size.present? || max_size.present?
      sizes = Model::SIZES  # ordered array
      range = sizes[(sizes.index(min_size) || 0)..(sizes.index(max_size) || -1)]
      scope = scope.where(models: { size: range })
    end

    scope
  end

  def vehicle_eligible?(vehicle)
    matching_vehicles_scope.where(vehicles: { id: vehicle.id }).exists?
  end
end
```

This lets the UI show "eligible ships" when a member clicks a slot, filtering their fleet vehicles.

## Frontend Pages

### Fleet Navigation Addition

Add to the fleet sub-navigation (alongside Ships, Members, Stats, Settings):
- **Missions** — `/fleets/:slug/missions`
- **Events** — `/fleets/:slug/events`

### Pages

| Route | Component | Description |
|-------|-----------|-------------|
| `/fleets/:slug/missions` | `MissionsList.vue` | Grid/list of mission templates |
| `/fleets/:slug/missions/new` | `MissionForm.vue` | Create mission with slot builder |
| `/fleets/:slug/missions/:missionSlug` | `MissionDetail.vue` | View mission, create event from it |
| `/fleets/:slug/missions/:missionSlug/edit` | `MissionForm.vue` | Edit mission |
| `/fleets/:slug/events` | `EventsList.vue` | Upcoming / past events, filterable by status |
| `/fleets/:slug/events/new` | `EventForm.vue` | Create event (from mission or ad-hoc) |
| `/fleets/:slug/events/:eventSlug` | `EventDetail.vue` | Full event view with slot board + sign-ups |
| `/fleets/:slug/events/:eventSlug/edit` | `EventForm.vue` | Edit event |
| `/fleets/:slug/settings/discord` | `DiscordWebhooks.vue` | Manage Discord webhook integrations |

### Mission Slot Builder (key UI component)

A dynamic form section within `MissionForm.vue`:
- Add/remove/reorder slots
- Each slot has:
  - Title (free text)
  - Description (optional)
  - Required toggle
  - Quantity spinner (1-20)
  - **Ship filter criteria** (each optional, narrowing the match):
    - Specific model (autocomplete search)
    - Classification dropdown (from `Model.classifications`)
    - Focus dropdown (from `Model.focus_filters`)
    - Size range (min/max dropdowns)
    - Min crew (number input)
    - Min cargo SCU (number input)

### Event Sign-up Board

The `EventDetail.vue` page shows a visual slot board:
- Each slot displayed as a card
- Shows criteria icons (ship class, size, cargo)
- Filled positions show member avatar + ship name
- Open positions show "Sign Up" button
- Clicking "Sign Up" opens a picker showing the member's eligible fleet vehicles
- Real-time updates via ActionCable

## Implementation Phases

### Phase 1 — Database & Models
- Migration for `missions`, `mission_slots`, `fleet_events`, `event_slots`, `event_sign_ups`, `fleet_discord_webhooks`
- ActiveRecord models with validations, associations, AASM (fleet_events)
- Vehicle matching logic on EventSlot
- Privilege constants on each model
- Update `FleetRole.all_available_privileges` to include new privileges
- Update default role privileges

### Phase 2 — Policies
- `MissionPolicy` — CRUD scoped to fleet membership + privileges
- `FleetEventPolicy` — CRUD + state transitions scoped to privileges
- `EventSignUpPolicy` — create/update own, manage others with privilege
- `FleetDiscordWebhookPolicy` — CRUD scoped to privileges

### Phase 3 — API Controllers & Routes
- `Api::V1::MissionsController` — CRUD with nested slots
- `Api::V1::FleetEventsController` — CRUD + state transition actions
- `Api::V1::EventSignUpsController` — sign-up management
- `Api::V1::FleetDiscordWebhooksController` — webhook CRUD + test
- Route definitions in `config/routes/api/fleets_routes.rb`

### Phase 4 — Views (JBuilder) & API Schema
- JBuilder templates for all new resources
- API component schemas (inputs + outputs)
- Generate OpenAPI schema

### Phase 5 — ActionCable Channel
- `FleetEventsChannel` for real-time event updates
- Broadcast on event state changes and sign-up changes

### Phase 6 — Discord Webhook Integration
- `Discord::FleetEventNotification` webhook class (extends existing pattern)
- `Discord::FleetEventNotificationJob` background job
- AASM callbacks on FleetEvent to enqueue Discord notifications
- Support for creating new messages and editing existing ones
- Encrypt webhook URLs at rest

### Phase 7 — RSpec Request Specs
- Mission CRUD specs
- Fleet event CRUD + state transition specs
- Sign-up flow specs
- Discord webhook CRUD + test specs
- Vehicle matching specs

### Phase 8 — Frontend: Missions
- Mission list page
- Mission form with slot builder
- Mission detail page
- Orval client regeneration

### Phase 9 — Frontend: Events
- Event list page (with status filters)
- Event form (from mission or ad-hoc)
- Event detail page with sign-up board
- Real-time updates via ActionCable
- Orval client regeneration

### Phase 10 — Frontend: Discord Settings
- Discord webhooks management page in fleet settings
- Webhook form (URL, name, event types)
- Test webhook button

### Phase 11 — Frontend: Navigation & Polish
- Add Missions / Events to fleet sub-navigation
- Add fleet event notification types to notification center (if Phase 13 of notification-center-backend is done)
- Empty states, loading states, error handling
- Responsive design for mobile

## Decisions

### D1 — Missions as templates, events as instances
Missions are reusable templates; events are concrete scheduled instances. This avoids coupling scheduling concerns into the template and lets fleets run the same mission multiple times. Ad-hoc events (no mission template) are also supported for one-off activities.

### D2 — Slot criteria use existing Model attributes
Rather than inventing a new taxonomy, slots filter against `classification`, `focus`, `size`, `cargo`, and `min_crew` — all already on the Model table and populated from SC data. This means slot criteria automatically stay current as ship data is updated.

### D3 — Per-fleet Discord webhooks, not a bot
Using Discord webhooks (not a bot) is the right choice because:
- No bot token management or OAuth flows
- Fleet admins create webhooks in their own Discord server settings
- Already using `discordrb-webhooks` gem for global notifications
- Simpler to deploy and maintain
- Each fleet can have multiple webhooks for different channels

### D4 — Event slots are copies, not references
When creating an event from a mission, slots are copied into `event_slots`. This means the mission template can be updated without affecting in-progress events, and ad-hoc slots can be added to specific events.

### D5 — Sign-ups are per-slot, not per-event
A member signs up for a specific slot with a specific vehicle. This enforces the mission requirements and gives organizers visibility into what ships are committed. A member can sign up for multiple slots if they have multiple ships.

### D6 — Webhook URL encryption
Discord webhook URLs are stored encrypted (using Rails credentials or `attr_encrypted`) since they grant posting access to Discord channels. The URL is never exposed in API responses — only the webhook name and settings.

### D7 — AASM for event lifecycle
Using AASM (already used for FleetMembership) provides a clean state machine with guard clauses, preventing invalid transitions and providing hooks for side effects (Discord notifications, ActionCable broadcasts).

## Out of Scope (Future)

- **Discord bot integration** (slash commands, RSVP reactions) — webhooks-only for v1
- **Recurring events** (weekly mining ops) — can be added later with a recurrence rule on events
- **Cross-fleet events** — v1 is single-fleet only
- **Event chat/comments** — could integrate with notification center later
- **Public event pages** — v1 is fleet-members-only; public sharing can be added later
- **Calendar export (iCal)** — nice-to-have, not in initial scope
