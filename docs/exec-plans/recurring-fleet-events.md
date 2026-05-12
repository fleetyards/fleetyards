# Recurring fleet events

## Why

Fleets run standing in-game events — "Thursday Play Evening", "Sunday
Cargo Run", "Monthly Fleet Meeting". Today every occurrence has to be
created by hand. Members want a calendar view that shows next Thursday's
event without an organiser remembering to spin one up each week, and
they want each occurrence to be a real event they can sign up for,
comment on, sync to Discord, etc.

## Shape

A **series** holds the cadence and the defaults. Real `FleetEvent`
rows ("occurrences") are pre-materialised in a rolling window and
behave exactly like one-off events. Editing an occurrence touches only
that occurrence; editing the series propagates to future
non-overridden occurrences. Cancelling an occurrence skips that week
without ending the series.

This reuses everything else we've built (auto-lock, ICS feed,
calendar grid, signups, Discord sync, notifications, lifecycle) on a
per-occurrence basis — the series layer is purely about templating
and generation.

## Data model

### `fleet_event_series`

| column                       | type                | notes |
|------------------------------|---------------------|-------|
| `id`                         | uuid                | pk    |
| `fleet_id`                   | uuid                | fk    |
| `created_by_id`              | uuid                | fk → users |
| `slug`                       | string              | unique per fleet |
| `title`                      | string              | inherited by occurrences |
| `description`                | text                | inherited |
| `briefing`                   | text                | inherited |
| `category`                   | enum                | inherited |
| `scenario`                   | string              | inherited |
| `location`                   | string              | inherited |
| `meetup_location`            | string              | inherited |
| `visibility`                 | enum                | inherited |
| `timezone`                   | string              | inherited (cadence is in this tz) |
| `duration_minutes`           | integer             | per occurrence |
| `auto_lock_enabled`          | boolean             | inherited |
| `auto_lock_minutes_before`   | integer             | inherited |
| `cover_image_preset`         | string              | inherited |
| `cover_image`                | uploader            | inherited |
| `cadence`                    | enum                | `weekly` (v1) |
| `day_of_week`                | integer (0–6)       | weekly cadence |
| `start_time_of_day`          | time                | wall-clock in series timezone |
| `until_date`                 | date, nullable      | last date occurrences may fall on |
| `max_occurrences`            | integer, nullable   | alternative to `until_date` |
| `active`                     | boolean             | false = generation paused, existing occurrences keep working |
| `archived_at`                | timestamp, nullable | mirrors event archive semantics |
| `created_at`/`updated_at`    | timestamps          |       |

Series **structure** (teams → ships → slots) is its own set of records
mirroring `fleet_event_team` / `fleet_event_ship` / `fleet_event_slot`:

- `fleet_event_series_team`
- `fleet_event_series_ship`
- `fleet_event_series_slot`

These act as the template that gets deep-copied into each new
occurrence at materialisation time. Treating them as separate tables
(vs. reusing the existing event-bound tables with a polymorphic
parent) avoids a polymorphic association on the slot tree and keeps
signup-related columns/indexes off the template path.

### `fleet_events` additions

| column                  | type             | notes |
|-------------------------|------------------|-------|
| `fleet_event_series_id` | uuid, nullable, fk → fleet_event_series | |
| `series_override`       | boolean default false | flips true when this occurrence is individually edited |
| `series_position`       | integer, nullable | 1-based ordinal within the series (for "occurrence 4 of 12") |

Index `(fleet_event_series_id, starts_at)` for the generator's
"already-materialised?" check and series detail listings.

## Generation

`FleetEvents::SeriesGenerationJob`, scheduled daily (~04:00 in fleet
timezone is fine — cron at a fixed UTC works for v1).

For each active, non-archived series:

1. Compute the next N candidate occurrence dates (default `WINDOW = 8`
   weeks for `cadence = weekly`).
2. Filter out candidates already materialised
   (`fleet_event_series_id = series.id AND starts_at = candidate`).
3. Filter out candidates past `until_date` or beyond `max_occurrences`.
4. For each remaining candidate, create a `FleetEvent` deep-copying:
   - All inherited scalar fields.
   - `starts_at` from `day_of_week` + `start_time_of_day` in the
     series timezone, resolved to UTC; `ends_at = starts_at +
     duration_minutes`.
   - Team/ship/slot tree from the series templates.
   - Cover image (re-attach the same blob, don't re-upload).
5. Set `series_position` to series.events.count + index.
6. Default `status = "draft"` — generation should NOT auto-publish.
   An organiser still hits Publish on each occurrence (or we add a
   `auto_publish_on_generate` flag on the series — TBD, see open
   questions).

Job is idempotent: re-running picks up only candidates not yet
materialised. Also runnable on demand from a series action ("Generate
next occurrences now") for organisers seeding a fresh series.

## Editing

### Editing an occurrence

The existing per-tab edit pages stay as-is. The save handler asks
the API to apply with one of three scopes when the occurrence belongs
to a series:

- `this_only` (default): writes go to the single occurrence. Sets
  `series_override = true` so future series edits stop overwriting it.
- `this_and_future`: writes go to the series (where the edited field
  exists on the series too — title, description, structure, etc.)
  AND propagate immediately to every future occurrence that is
  **not** overridden. Past occurrences and overridden ones are
  untouched.
- `all_in_series` (optional, v1.1): same as above but also stamps
  past non-overridden occurrences. Probably skip in v1 — historical
  data shouldn't quietly mutate.

UI: a small selector at the top of the edit form when
`fleet_event_series_id` is set. Default `this_only`. Hide entirely
for one-off events.

Per-occurrence fields that don't exist on the series (signups,
status transitions, archive, individual cancellation) always remain
occurrence-only and don't trigger the prompt.

### Editing the series

New route `/fleets/:slug/event-series/:series/edit/` mirroring the
event edit layout (basic / description / teams & slots). Saving
applies to the series itself plus a propagation pass to non-overridden
future occurrences.

### Cancelling

- Cancel one occurrence: the existing event-cancel flow. Series stays
  active and the next generation cycle won't re-create the same date
  (it's already materialised, just cancelled).
- End the series: a "End series" action sets `active = false`. Past
  occurrences keep working; future un-materialised dates stop being
  generated. Materialised-but-future occurrences are left in place —
  the organiser cancels them individually if they want them gone.
  (Open question: should "End series" also cancel future
  materialised occurrences? Probably opt-in via confirm dialog.)

## API

- `GET /fleets/:slug/event-series` — list active series.
- `POST /fleets/:slug/event-series` — create series. Triggers an
  immediate generation pass.
- `GET /fleets/:slug/event-series/:series_slug` — show + occurrences.
- `PATCH /fleets/:slug/event-series/:series_slug` — series edit,
  optional `propagate=true` (default true) to push to future
  occurrences.
- `DELETE /fleets/:slug/event-series/:series_slug` — soft-archive
  (sets `active = false`, then `archived_at` on second delete, same
  as event archive/destroy semantics).
- `POST /fleets/:slug/event-series/:series_slug/generate` — force a
  generation pass; useful after editing cadence.
- `PATCH /fleets/:slug/events/:event_slug` gains an
  `apply_to=this_only|this_and_future` body param when the event has a
  series.

Series team/ship/slot CRUD mirrors the existing event-side endpoints
under `/event-series/:series_slug/teams/...`.

## Frontend

- **Event create form**: a "Repeats" section toggles between one-off
  and recurring. When recurring, show cadence selector (weekly + day
  picker + start time + until/count). Submitting creates a series
  instead of an event; the API generates the first occurrences and
  redirects to the series page (or first occurrence — TBD).
- **Event detail page**: chip "Part of weekly series: Thursday Play
  Evening" → links to the series page. Status badge gains a
  `series_override` flag where applicable.
- **Event edit pages**: scope selector at the top when
  `fleet_event_series_id` is set, defaulting to `this_only`.
- **New `/fleets/:slug/event-series/` index** with active series.
- **New series detail page** showing the next N occurrences and a
  history toggle.
- **Calendar grid** already renders FleetEvents — no change.

## Out of scope for v1

- Non-weekly cadences (daily, biweekly, monthly, custom intervals,
  multi-day BYDAY). Slot in by extending `cadence` enum and the
  generator's date-computing helper.
- iCalendar EXDATE-style exception records — handled via
  occurrence-level cancellation.
- Bulk re-materialisation after schema drift (e.g. organiser changes
  cadence from weekly to biweekly). v1 keeps already-materialised
  occurrences as-is; only un-materialised future dates pick up the
  new cadence.
- Signups inheriting across occurrences ("I'm in for every Thursday")
  — too footgun-prone. Members sign up per occurrence.

## Open questions

1. **Auto-publish?** Should generated occurrences start in `draft` or
   `open`? Drafts give organisers a chance to tweak; `open` means
   signups can begin the moment the occurrence materialises. Lean:
   add `auto_publish_on_generate` to the series, default true (most
   series want the rolling window visible to members).
2. **Discord sync on generation?** Series-level Discord push would
   keep Discord scheduled events in sync without an organiser hitting
   Sync per occurrence. Tied to (1) — only push for `open`+ status.
3. **Series creator vs. event creator** for admin role checks: do
   occurrences inherit event-admin grants from the series, or does
   the series creator implicitly admin every occurrence? Probably
   the latter for simplicity.
4. **Window size**: 8 weeks default ahead. Configurable per-fleet or
   per-series, or app-wide constant for v1? Lean: constant for v1.
5. **Timezone semantics**: store cadence in series timezone, materialise
   to UTC at generation time. DST handling: a "Thursday 8pm" series
   correctly stays at 8pm local through DST shifts because the
   generator resolves day/time → UTC on each candidate. Confirm.
6. **Migration**: any existing standing events organisers manually
   re-create weekly — do we want a "Convert to series" action that
   reads an existing event and seeds a series from it? Nice-to-have,
   not blocking.

## Rollout

1. Schema migrations + model layer + factories.
2. Series CRUD endpoints + generation job (no UI yet; verify with
   specs / curl).
3. Event create form gains the Repeats toggle.
4. Series detail + edit pages.
5. Occurrence-edit scope selector.
6. Calendar/detail page series chip.
7. Auto-publish + Discord sync wiring (depends on open question (1)).

Each step is independently shippable behind a `recurring_events`
Flipper flag if we want to dogfood internally first.
