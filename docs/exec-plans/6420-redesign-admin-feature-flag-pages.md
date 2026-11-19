# Redesign the admin feature flag pages

Working plan for #6420. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The admin feature flag list and detail pages match the approved design: one detail page instead of four tabs, and one readable row per flag on the list.

## What changed

### Phase 1 — Detail page
1. `/features/:name/` renders one page; the Users, Fleets and History child routes go away.
2. Header: name, state pill, last change, "Open to everyone", "Turn off" through BtnConfirm.
3. "On for" summary built from the flag's gates.
4. Rollout panel: groups as Chips, share of users / share of requests as a draft slider + number input + Apply, both opt-in toggles.
5. FeatureHistory takes a limit and expands in place to everything the API returns.
6. Users and fleets panel: segmented switch, add select + Add, ActorList.

### Phase 2 — List page
1. One row per flag linking to the detail page: state, name and kind, who has it, last change.
2. Filter input and segmented All / Rollout / Permanent with counts; no per-row toggle.

### Phase 3 — Translations and tests
1. New strings in all seven locales; drop keys nothing reads any more.
2. Specs for the new components; remove specs of deleted pages.

## Intent Verification

- [ ] Detail page shows every gate at once and saves each change through the existing admin endpoints
- [ ] Percentages are only sent on Apply
- [ ] Turn off asks first
- [ ] List has no per-row toggle, filters by name and kind
- [ ] Phone width: nothing overflows, toolbars wrap

## Key files

| File | Role |
|------|------|
| `app/frontend/admin/pages/features/[name].vue` | Detail page |
| `app/frontend/admin/pages/maintenance/features.vue` | List page |
| `app/frontend/admin/components/Features/` | Rollout, percentage gate, actors panel, summary |
| `app/frontend/admin/components/FeatureHistory/index.vue` | History list |
| `app/frontend/admin/composables/useFeatureActions.ts` | Gate writes |

## Discovery Log

- **2026-11-19** History API returns at most 50 changes, so "full history" expands in place instead of a separate page. A history row's `thing` for an actor is the Flipper id, not a name, so rows keep their current wording.
- **2026-11-19** Phone: three tab labels with counts do not fit a 390px segmented control; counts hide below the desktop breakpoint.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
