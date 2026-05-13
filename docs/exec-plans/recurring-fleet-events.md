# Recurring fleet events (RRULE-on-event)

## Why

Fleets run standing in-game events — "Thursday Play Evening", "Sunday
Cargo Run". The first attempt modelled this with a separate
`FleetEventSeries` table + materialised occurrences, which turned out
to be over-engineered for the actual use case (one-shape weekly
event, occasionally skip a week).

This take stores the recurrence rule on the `FleetEvent` itself and
expands occurrences on the fly — closer to how iCalendar (RRULE/EXDATE)
and most lightweight calendar products work.

## Data model

### `fleet_events` additions

| column                  | type              | notes |
|-------------------------|-------------------|-------|
| `recurring`             | boolean default false | toggle |
| `recurrence_interval`   | string, nullable  | enum: `daily`, `weekly`, `biweekly`, `monthly` (null when not recurring) |
| `recurrence_until`      | date, nullable    | last date occurrences may fall on |
| `recurrence_count`      | integer, nullable | alternative to `recurrence_until`; mutually exclusive |
| `excluded_dates`        | date[]            | array of `YYYY-MM-DD` dates to skip |

`starts_at` keeps its current meaning: the *first* occurrence of the
series. Recurrence is computed forward from there.

### `fleet_event_signups` additions

| column            | type           | notes |
|-------------------|----------------|-------|
| `occurrence_date` | date, nullable | required when signing up for a recurring event |

Existing one-off signups leave it null. Index
`(fleet_event_id, occurrence_date, fleet_membership_id)` for "is this
member already signed up for this occurrence?" checks.

## Expansion helper

`FleetEvent#occurrences(from:, to:)` — returns an array of
`Time`s representing each materialisable occurrence start time within
the range, honouring `recurrence_until`, `recurrence_count`, and
`excluded_dates`. For non-recurring events, returns `[starts_at]` if
it falls inside the range, else `[]`.

`FleetEvent#next_occurrence(after:)` — convenience for the
notification jobs.

## API surface

- `POST /fleets/:slug/events` and `PATCH .../events/:slug` accept the
  new fields. Input schemas extended.
- `GET .../events` and `GET .../calendar` expand recurring events
  into virtual entries within the requested range. The serialised
  payload looks the same as a one-off (own `slug`, own `startsAt`,
  etc.) except for an added `occurrenceDate` and `parentEventSlug`
  field. The frontend treats them like events.
- `POST .../events/:slug/skip-occurrence` body `{ date: "YYYY-MM-DD" }`
  appends to `excluded_dates`. Used by the "Skip this occurrence"
  button.
- `POST .../events/:slug/end-series-here` body `{ date }` sets
  `recurrence_until` to the date before. Used by "Stop here and
  going forward".
- Signup endpoints accept an optional `occurrenceDate` and reject if
  the event is recurring and the date wasn't provided.

## ICS export

`Calendars::IcsBuilder` learns to emit a single VEVENT per recurring
event with:

- `RRULE:FREQ=WEEKLY;BYDAY=TH` (or `DAILY`, `WEEKLY;INTERVAL=2`,
  `MONTHLY` for the other intervals)
- `UNTIL=…` or `COUNT=…` translated from the columns
- `EXDATE:…` lines per excluded date

Apple/Google/Outlook expand them client-side. Per-occurrence overrides
aren't needed for MVP.

## Frontend

### Event create/edit form

A "Repeats" section near the date picker:

- Toggle: **Repeats**
- When on:
  - Interval dropdown: Daily / Weekly / Every other week / Monthly
  - End condition (radio + one input): **Never** / **On date** /
    **After N occurrences**
- `startsAt` keeps its job: pick the first occurrence.

Submit-time logic stays in `EventForm`; no separate endpoint.

### Event detail page

For recurring events:

- Hero shows "Repeats weekly · until <date>" / "Repeats weekly".
- A new "Upcoming occurrences" panel listing the next ~12 dates with:
  - the date
  - "Excluded" badge if in `excluded_dates`
  - a "Skip" button per row for managers (POSTs to skip-occurrence)
  - a "Stop here and going forward" item at the bottom

For a virtual occurrence (when the user lands on `/events/:slug` with
`?occurrence=…` query param), the page shows the same hero but
contextualised to that date, and the signup CTA scopes to that
occurrence.

### Calendar grid

No change needed in the frontend — the API returns one entry per
occurrence in the range.

## Auto-lock + starting-soon jobs

For MVP these jobs do *not* operate on recurring events. They run
only against one-off events. Reasoning: per-occurrence lock state
would require either materialising rows (back to the original design)
or a small `fleet_event_occurrence_states` table that's out of scope
here. Document as a follow-up.

## Discord sync

Same: skipped for recurring events in MVP. The org can still hit Sync
to push the *next* occurrence as a one-off Discord scheduled event if
they want.

## Out of scope (follow-ups)

- Per-occurrence overrides ("this Thursday is at a different
  location"). Would need an `event_occurrence_overrides` table.
- Auto-lock / starting-soon / Discord sync for recurring events.
  Would need a small per-occurrence state table.
- "Apply to: this and following events" edit-scope dialog. With the
  RRULE model this is two operations: set `recurrence_until` on the
  current event, create a new event from that date with the new
  fields. Worth doing once the basic flow is in.
- Custom intervals ("every 3 weeks") and multi-day weekly
  (Tue + Thu). Easy follow-up by widening the interval enum.

## Rollout

1. Migration + model helper + specs for `FleetEvent#occurrences`.
2. API input/output schema changes + expansion in listing endpoints
   + skip/end-series-here endpoints + specs.
3. ICS export learns RRULE/EXDATE.
4. Signup schema + endpoint update.
5. Frontend Repeats section on the event form.
6. Frontend recurring detail page + occurrences panel.

Each step is independently shippable.
