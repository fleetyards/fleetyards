# Recurring Fleet Event Occurrence Dates

**Date:** 2026-09-26 (research during custom recurrence intervals and series splits, #5178)

A recurring fleet event keeps its whole series on one row. Its occurrences are identified by a date, and that date is keyed in two different timezones depending on who reads it. Read this before changing how occurrences are expanded, or before adding anything that stores an occurrence date.

## Two timezones for one date

- **Stored keys are Berlin dates.** `FleetEvent#occurrences` returns times in `Time.zone` (Berlin, from `config/application.rb`), and callers key everything by `occurrence.to_date`. That covers `fleet_event_signups.occurrence_date`, `fleet_event_occurrence_states.occurrence_date`, `excluded_dates`, the `?occurrence=` parameter and `upcomingOccurrences[].date`.
- **Rebuilt times use the event's zone.** The calendar feed (`occurrence_start`), the Discord sync (`effective_starts_at`) and the show payload take `starts_at` in the event's own zone and `change` its date to the key.
- **`recurrence_until` is read in the event's zone** as that local day's end.

The two agree for every event whose local date and Berlin date are the same, which covers most European fleets. They disagree for a series near local midnight far from Berlin. A New York event at 19:00 is 01:00 the next day in Berlin, so it is keyed on the next day, and whatever rebuilds its time from the key puts it a day late.

## What stays consistent because of this

- Plain intervals (daily/weekly/monthly every N) step from `starts_at` in `Time.zone`. Stepping in the event's zone would be more correct across DST, but it would re-key existing late-evening series and orphan their signups, overrides and skipped dates.
- Weekday patterns are laid out in the event's zone, because the weekdays are the organiser's own. They had no stored rows when they were introduced.
- `FleetEvent#until_before(date)` turns a key into the `recurrence_until` that ends the series just before that occurrence, using the occurrence's local date. Ending or splitting a series with `key - 1` kept the occurrence or dropped the one before it.

## Fixing it properly

Key occurrences by the event-local date everywhere, which means having `occurrences` return times in the event's zone. That needs a data migration re-keying the stored dates of every recurring event whose local and Berlin dates differ. The migration has to run in one step with the expansion change, or the old keys stop matching.
