# Recurring events: "this and following" edits and custom intervals

Working plan for #5178. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A recurring event can repeat every N days/weeks/months and on several weekdays, and an organiser can split a series at an occurrence in one action, with signups, ICS and Discord following both changes.

## What changed

### Phase 1 — Custom intervals (backend)
1. Migration: `recurrence_every` (integer, not null, default 1) and `recurrence_weekdays` (integer[], not null, default []).
2. `FleetEvent`: validations (every >= 1, weekdays 0–6 and weekly only), normalisation (biweekly reads as weekly/2, the start day is added to the weekdays), and an `occurrences` expansion with BYDAY support, computed in the event's zone.
3. Policy params, create/update input components, the event component and jbuilder.
4. ICS: `INTERVAL`, `BYDAY` and `WKST=MO`.
5. Discord announcement recurrence text: every N plus weekdays, in all 7 locales.
6. `upcomingOccurrences` on the show payload.

### Phase 2 — Split series (backend)
1. `FleetEvent#split_at!(date)`: copy the event and its tree, then move signups/states/excluded dates on or after the date and remap slots.
2. `POST split-series` controller action, route, swagger test and schema.
3. Discord: re-upsert the moved occurrence states so their links point at the new event.

### Phase 3 — Frontend
1. Schedule form: frequency select (daily/weekly/monthly), an "every N" input, and weekday toggles for weekly.
2. A recurrence label composable, used by the event page chip and EventPanel.
3. Event page: occurrences from `upcomingOccurrences`, plus an "Edit this and following" action (split, then navigate to the new event's edit page).
4. Labels in all 7 locales.

## Intent Verification

- [x] **Split** — splitting at an occurrence ends the old series the day before and creates a new one starting there. Later signups, slot signups included, show up on the new event.
- [x] **Every N / weekdays** — "every 3 weeks" and "weekly on Tue + Thu" expand correctly in `occurrences`, the calendar endpoint and the event page.
- [x] **ICS** — RRULE carries INTERVAL/BYDAY. After a split, the old VEVENT has an UNTIL and the new event gets its own UID.
- [x] **Discord** — `sync_to_discord` pushes the custom-interval occurrences. After a split, moved Discord events are re-upserted under the new event.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_event.rb` | recurrence expansion, split |
| `app/controllers/api/v1/fleet_events_controller.rb` | split-series action |
| `app/lib/calendars/ics_builder.rb` | RRULE |
| `app/jobs/discord/sync_fleet_event_job.rb` | occurrence resync after split |
| `lib/discord/event_published.rb` | recurrence text |
| `app/frontend/frontend/pages/fleets/[slug]/events/[event]/edit/schedule.vue` | recurrence form |
| `app/frontend/frontend/pages/fleets/[slug]/events/[event].vue` | occurrence list and actions |

## Not in scope (deferred)
- **Monthly by weekday ("second Tuesday")** — not asked for; monthly stays on the day of the month. Dropped rather than filed.

## Discovery Log

- **2026-09-26** Initial research. The event page expanded occurrences client-side in UTC while the server keys them by Berlin date, so they are now served by the API. The monthly expansion stepped from the previous occurrence, so Jan 31 drifted to the 28th for good; it now steps from the start.
- **2026-09-26** Plain intervals keep stepping in Time.zone (Berlin), because stored occurrence dates are keyed there. Stepping in the event's zone would re-key late-evening non-Berlin series. Only weekday patterns (no legacy rows) use the event's zone. Occurrence keys vs. the event-local dates that ICS/Discord/show rebuild from remain a pre-existing mismatch.
- **2026-09-26** A split copies tree rows with `save!(validate: false)`. A ship whose model left the game would otherwise block the split.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
