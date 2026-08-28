# Notification Call-to-Actions

Every one of the 24 notification types renders the same generic "Open" button in the reading pane, and nothing at all in the list rows. A fleet invite — which asks the reader for an answer — looks exactly like "Aurora MR added to your hangar", which asks for nothing. This plan gives each notification an action that fits its occasion, in three tiers: an honest label, secondary targets (calendar, store), and real mutations (accept an invite, decline a request, retry a sync).

## The problem with mutations

An invite may have been answered elsewhere, an event may have started, sign-ups may be locked. A button that then throws a 422 is worse than no button.

So the notification carries a **reference to its record**, and the reading pane loads that record when the notification is opened. The fetched state — not the notification — decides which actions appear.

`Notification` already has `record_type`/`record_id` (polymorphic). The API exposes neither.

## Payload

New `record` block in `app/views/api/v1/notifications/_base.jbuilder`:

```ruby
json.record do
  json.type ...        # fleet_membership | fleet_event | fleet_inventory | vehicle | hangar_sync
  json.id ...
  json.fleet_slug ...  # only what the matching endpoint needs to load it
  json.event_slug ...
  json.username ...
end
```

A flat object with optional fields rather than a `oneOf` discriminator: the OpenAPI components in this repo are hand-written, and a union costs more than it carries.

`_notification.jbuilder` caches on `["v1", notification]`, so this block must carry **no live state** — a cached row would serve a stale status. Reference only.

## Record lookups

| `record.type` | Endpoint | State read |
|---|---|---|
| `fleet_membership` (own) | `GET /fleets/:slug/membership` | `status` |
| `fleet_membership` (someone else's) | `GET /fleets/:slug/members/:username` **(new)** | `status` |
| `fleet_event` | `GET /fleets/:slug/events/:slug` | `status`, `signups_open`, `past` |
| `vehicle` | `GET /vehicles/:id` | `wanted` |
| `hangar_sync` | `GET /hangar/sync-rsi-hangar/status` | `active` |

Three render states: **loading** → link CTA only; **resolved** → the actions the state allows; **gone/403** → a "no longer available" note plus the link. On success the record query and the notification list are invalidated and the notification is marked read; archiving stays a deliberate act.

## Backend work

| Change | File |
|---|---|
| `record` block + OpenAPI component | `app/views/api/v1/notifications/_base.jbuilder` |
| `GET /fleets/:slug/members/:username` | `config/routes/api/fleets_routes.rb`, `app/controllers/api/v1/fleet_members_controller.rb` |
| Attach the import as the sync record | `app/lib/hangar_sync.rb` |
| Point the inventory link at the inventory | `app/models/fleet_inventory_item.rb` |

`fleet_members` currently exposes `index create destroy` plus the member actions; `set_member` and the doorkeeper scopes already exist, so `show` is a route, an action with `authorize!`, and a jbuilder reusing `_base`.

## Frontend

A registry — `notification_type → { labelKey, record?, actions(state) }` — in `frontend/composables/useNotificationActions.ts`. The reading pane and the list row render from it generically, which keeps the state logic unit-testable without mounting Vue.

Labels under `labels.notificationActions.*` in all seven locales.

### Tier 1 — label and link (all types)

"Open" becomes type-specific; list rows get the same link button. For the twelve pure statements of fact (`hangar_create`, `wishlist_*`, `fleet_event_started/completed/cancelled`, `fleet_event_signup_kicked`, …) that is the whole change — there is nothing to do about them.

Not affected: `NotificationsNav/index.vue` is a nav item with a badge, not a dropdown. There is no place for a CTA there.

### Tier 2 — mutations, reading pane only

List rows stay out: one record fetch per row would be N requests.

| Type | Action | Condition | Endpoint |
|---|---|---|---|
| `fleet_invite` | Accept / Decline | `status == invited` | `PUT /fleets/:slug/membership/accept\|decline` |
| `fleet_member_requested` | Accept / Decline | `status == requested` | `PUT /fleets/:slug/members/:username/accept\|decline` |
| `fleet_event_published`, `…_starting_soon` | Sign up | `signups_open && !past` | `POST /fleets/:slug/events/:slug/signup` |
| `fleet_event_signup_confirmed`, `…_assigned` | Withdraw | signup active | `DELETE /fleet-event-slots/:id/signup` |
| `hangar_sync_finished`, `…_failed` | Sync again | `!active` | `PUT /hangar/sync-rsi-hangar` |
| `model_on_sale` | Mark as bought | `wanted` | `PATCH /vehicles/:id` |

`EventSignupCta` carries three statuses and a vehicle picker. The notification offers only "Sign up" (`CONFIRMED`, no vehicle); anyone who wants more follows the link. The generated mutation clients are reused as-is.

### Tier 3 — secondary actions

- Calendar for every event type: `GET /fleets/:slug/events/:slug/event.ics` already exists.
- Store link for `model_on_sale`: `model.store_url` is already in the vehicle payload.
- A second target: event → fleet, admin sign-up notices → the roster rather than the event overview.

## Verification

- Integration tests (`openapi-ruby`) for the `record` block and for `fleet_members#show` including the policy case, then `./bin/generate-schema`.
- Vitest for `useNotificationActions`: state in, expected buttons out — including the expired cases (invite already answered, event past, sync running).
- `test/playwright/e2e/Notifications.spec.ts`. This needs `app/lib/notification_examples.rb` to create real records for the first time; none of its eight examples passes a `record:` today, and without one tier 2 is invisible to the e2e run.
- By hand: trigger an invite in a test fleet, accept it from the notification center, reopen the same notification — the actions must be gone.
