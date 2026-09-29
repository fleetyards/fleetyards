# Measure installs and push engagement

Working plan for #5237. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Page views by device, OS and install state can be read per day after visits are purged, with every in-app navigation counted as a view.

## Open questions

- None. Push tasks wait for #4980 (see the issue body).

## What changed

### Phase 1 — A view per navigation

1. `useAhoy.ts`: send `$view` from `router.afterEach` as well, skipping the initial navigation that the load-time view already covers, and keep `installed: true` on each.
2. Check that ahoy.js takes `url`/`page` from `window.location` after navigation (history is updated by the time `afterEach` runs).
3. Vitest for the composable: one view on load, one per later navigation, none on a same-path query change if that proves noisy.

### Phase 2 — `Views by device` rollup

1. `app/jobs/metrics_job.rb`: daily rollup of `$view` events joined to `ahoy_visits`, dimensions `device_type`, `os`, `installed`, same 2-day recompute and cleanup-cutoff guard as `Visits by OS`.
2. Test alongside `track_visits_by_os` in `test/jobs/metrics_job_test.rb`.

## Intent Verification

- [ ] **Navigations count** — moving between two pages in the SPA writes two `$view` events on one visit.
- [ ] **Survives the purge** — a `Views by device` rollup row exists per day with `device_type`/`os`/`installed` dimensions after `Cleanup::VisitsJob` deletes the visits.
- [ ] **Existing stats unaffected** — admin `most_viewed_pages` still reads `properties->>'page'` (it gets more rows, not a new shape).

## Key files

| File                                               | Role                                                          |
| -------------------------------------------------- | ------------------------------------------------------------- |
| `config/initializers/ahoy.rb`                      | `Ahoy::Store`, copies `installed` from `$view` onto the visit |
| `app/frontend/frontend/composables/useAhoy.ts`     | sends the one `$view` per load                                |
| `app/jobs/metrics_job.rb`                          | daily rollups, incl. `Visits by OS`                           |
| `app/jobs/cleanup/visits_job.rb`                   | monthly purge of visits and events                            |
| `app/frontend/frontend/App.vue`                    | calls the load-time `$view` (line 59)                         |
| `app/controllers/admin/api/v1/stats_controller.rb` | `most_viewed_pages` reads `$view`                             |

## Not in scope (deferred)

- **Push opt-in by OS and click-through by type** — need push delivery from #4980; they stay unticked on #5237. When #4980 is built: store `os` on the subscription (no `visit_id` is planned there), and add `via=push` plus the notification type to the payload URL.

## Discovery Log

- **2026-09-29** Initial research. Task 1 shipped in #5243. Push (#4980) is unbuilt, which blocks tasks 2 and 3. `$view` is per page load, not per route.
- **2026-09-29** Decided: device rollup plus per-navigation views on this branch; push tasks wait for #4980.

## Progress

- [ ] Phase 1
- [ ] Phase 2
