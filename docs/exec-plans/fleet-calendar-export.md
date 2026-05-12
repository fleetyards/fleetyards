# Fleet calendar export (surface the ICS feed + per-event download)

## Why

We already ship an iCalendar subscription feed at
`GET /api/v1/fleets/:slug/events.ics?token=…`, but:

- Fleet members have no way to find that URL — the endpoint is live
  but unsurfaced in the UI.
- `calendar_feed_token` is a column on `fleets` but nothing populates
  it, so the endpoint returns 403 for every fleet until someone sets
  a token manually.
- There's no per-event "Add to calendar" affordance — useful when a
  member just wants Thursday's event in their calendar without
  subscribing to the whole fleet feed.

Calling this "CalDAV export" is shorthand; the real protocol is heavy
and bidirectional. What members actually want is what other event
products call a "Subscribe to calendar" link. This plan delivers that.

## Scope

1. Per-fleet calendar subscription feed, discoverable and rotatable
   from fleet settings.
2. Per-event one-shot `.ics` download from the event detail page.
3. Optional per-user filtered subscription feed
   ("events I've signed up for"). Cheap once the per-fleet feed is
   wired; nice for members who only want their own commitments.

## Out of scope

- Full CalDAV protocol (PROPFIND/REPORT/PUT, ETags, collection
  discovery).
- Email iMIP invites attached to signup confirmations.
- Two-way sync from calendar apps back into the signup state.

## Backend

### Token generation + rotation on `Fleet`

- `Fleet#ensure_calendar_feed_token!` — generates a `SecureRandom
  .urlsafe_base64(32)` if blank, otherwise no-op. Called lazily the
  first time the settings UI is loaded and explicitly on rotate.
- `Fleet#rotate_calendar_feed_token!` — regenerates the token,
  invalidating any subscribed clients. Audit-logged so admins can see
  who rotated and when.
- Don't auto-generate at fleet creation — leave blank until an admin
  opts in. Keeps the feed disabled by default.

### API

- `GET /fleets/:slug/calendar/subscription` — returns the feed URL,
  current token (so the UI can show "Active" vs "Not generated"),
  and the public ICS URL. Admin/manage scope only.
- `POST /fleets/:slug/calendar/subscription` — `ensure_…!` then
  return the URL. Idempotent.
- `DELETE /fleets/:slug/calendar/subscription` — clears the token
  (kills the feed).
- `POST /fleets/:slug/calendar/subscription/rotate` — rotates and
  returns the new URL.

Existing `GET /fleets/:slug/events.ics?token=…` stays as is.

### Per-event `.ics` download

- New `GET /fleets/:slug/events/:slug/event.ics` action that returns
  a one-shot `.ics` for the single event. Uses the same `build_ics`
  helper, factored out of `FleetCalendarsController` into a
  `Calendars::IcsBuilder` PORO so both endpoints share the format.
- Auth: respects `fleet:events:read`, same as the detail JSON.
- Headers: `Content-Disposition: attachment; filename="event-slug
  .ics"` so the browser saves rather than navigating to the file.

### Per-user filtered feed (optional, can be a follow-up)

- `GET /me/calendar/events.ics?token=…` where `token` is a per-user
  token on `users`. Filters fleet events the user is signed up for
  across all their fleets.
- New columns: `users.calendar_feed_token` mirroring the fleet one.
- Same token-generation/rotation pattern.

### Shared ICS builder

Factor `build_ics` out of `FleetCalendarsController` into
`app/lib/calendars/ics_builder.rb`. Add a few missing fields useful
for calendar clients:

- `URL:` pointing to the event detail page.
- `CATEGORIES:` from the event's mission category.
- `LAST-MODIFIED:` (separate from `DTSTAMP`).
- `ORGANIZER:CN=<fleet name>` (no mailto — purely informational).
- `X-WR-TIMEZONE` on the calendar wrapper matching the event's
  timezone, helping clients show times in the right zone.
- A `VTIMEZONE` block per distinct event timezone so DST-correct
  rendering doesn't depend on the client's TZ database. Skip if every
  event in the response is already UTC.

## Frontend

### Fleet settings — new "Calendar Subscription" section

Lives on `/fleets/:slug/settings/fleet/` (the existing fleet settings
page) under the existing settings layout. Visible to anyone with
`fleet:manage` or `fleet:events:manage`.

- **Disabled state** (token blank): single CTA "Generate
  subscription link". Clicking calls
  `POST .../calendar/subscription` and switches to enabled state.
- **Enabled state**:
  - Read-only input with the full feed URL, with a Copy button.
  - "Rotate link" button (confirms in a modal — explains that
    existing subscribers will silently stop receiving updates).
  - "Disable subscription" button (also confirms).
  - Helper text: short instructions for Apple Calendar / Google
    Calendar / Outlook ("Add by URL"). Keep it terse with links.

### Event detail — "Add to calendar" button

- Inline `<a>` (server-rendered href) next to the existing breadcrumb
  actions, downloading `/fleets/:slug/events/:slug/event.ics`.
- No JS needed — browser handles the download. Just an `<a download>`.
- Visible to anyone with read access to the event.

### Optional: My account — personal subscription

- `/settings/notifications/` (or a new "Calendar" tab) shows the
  personal feed URL with the same generate/rotate/disable pattern.
- Defer until the fleet-level UX is in users' hands.

## Security

- Tokens are bearer tokens in a URL. Calendar clients store them, so
  rotation is the recovery path if a token leaks.
- The endpoint already short-circuits on token mismatch (403). No
  rate limiting today — add a basic Rack::Attack rule on the ICS
  endpoint as a safety net.
- The personal feed token shouldn't expose other users' data —
  scope the query to the signed-up user's signups only.

## Testing

- Request specs for the new subscription endpoints (auth scopes,
  generate, rotate, disable, GET returns URL).
- Request spec for the per-event ICS endpoint (auth, content-type,
  filename, body parse round-trips through `Icalendar.parse`).
- Unit spec for `Calendars::IcsBuilder` covering escaping, VTIMEZONE
  emission for non-UTC events, URL, status mapping, cancelled events
  emitting `STATUS:CANCELLED` rather than being filtered out (so
  subscribed clients see the cancellation rather than the event
  silently disappearing).

## Open questions

1. **Should cancelled events stay in the feed with `STATUS:CANCELLED`,
   or be filtered out?** Today they're filtered. Keeping them with a
   cancelled status is the iCalendar-idiomatic behaviour and lets
   subscribed clients show the strike-through; filtering means
   subscribed clients silently drop the event. Lean: emit with
   `STATUS:CANCELLED` for at least 7 days past `starts_at`, then
   drop.
2. **Past event horizon**: today the feed returns all non-archived
   events forever. Calendar clients will happily render years of
   history. Probably cap at "last 90 days + everything future" to
   keep payloads bounded.
3. **Discord-synced events**: Discord already creates its own
   scheduled events; the ICS feed duplicates them in the user's
   calendar if they're also Discord-subscribed. Nothing to do here,
   but worth a note in the UI helper text.

## Rollout

1. Backend: token gen/rotate on Fleet, subscription endpoints, shared
   `IcsBuilder`, per-event `.ics` endpoint, specs.
2. Frontend: fleet settings Calendar Subscription section.
3. Frontend: event detail "Add to calendar" button.
4. (Optional) Personal feed token + endpoint + account-settings UI.

Steps 1–3 can ship as one PR; step 4 as a follow-up.
