# Measure installs and push engagement

Working plan for #5237. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Every visit records whether it ran as the installed app, and a daily rollup keeps that per OS beyond the one-month visit purge.

## What changed

### Phase 1 — Installed flag on visits
1. `ahoy_visits.installed` boolean, default false.
2. The app sends `installed: true` with its `$view` when `isInstalledApp()` holds; `Ahoy::Store#track_event` copies it onto the visit. The visit itself is created server-side on the HTML request, before any script can see the display mode.
3. `isInstalledApp` moves out of `useInstallPrompt` into `shared/utils/DisplayMode` so both use one check.

### Phase 2 — Rollup
1. `MetricsJob` rolls up `Visits by OS` per day with `os` and `installed` dimensions.

## Intent Verification

- [x] **A `$view` from the installed app marks its visit installed** — `test/integration/ahoy_installed_visit_test.rb`
- [x] **Installed share per OS survives the visit purge** — `MetricsJob` rollup test

## Key files

| File | Role |
|------|------|
| `config/initializers/ahoy.rb` | Store hook copying the flag onto the visit |
| `app/frontend/frontend/composables/useAhoy.ts` | Sends the flag with the page view |
| `app/frontend/shared/utils/DisplayMode.ts` | Installed-app detection |
| `app/jobs/metrics_job.rb` | Daily rollup by OS and installed |

## Not in scope (deferred)

- **Push opt-in by OS, push click-through** — need `PushSubscription` and push delivery from #4980; stay on #5237.
- **Saved query for page views by device** — only useful once fleet events and contracts have a month of use; stays on #5237.

## Discovery Log

- **2026-09-27** Visits are server-side (`server_side_visits`, cookies `:none`); ahoy.js never creates one, so `visitParams` cannot carry the flag. The `$view` event finds the same visit through the visitor anonymity set.

## Progress
- [x] Phase 1
- [x] Phase 2
