# Hangar sync: no-op runs still count as a sync

Working plan for #5554. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A hangar sync run whose outcome is `nothing_to_sync` or `only_skipped_items` no longer appears on the user's imports page or in the weekly report's `hangar_syncs` figure.

## What changed

### Phase 1 — Tell no-op runs apart
1. `HangarSync::NO_OP_OUTCOMES` — the outcomes that skip every sync step.
2. `Import.without_no_op_syncs` — excludes rows whose `output->>'outcome'` is a no-op outcome; rows without an outcome (every other type, failed and pre-outcome runs) stay.

### Phase 2 — Use it
1. `Api::V1::ImportsController#index` lists through the scope. `show` keeps working by id.
2. `AdminWeeklyReport` counts `hangar_syncs` through the scope.

## Intent Verification

- [ ] **No-op runs off the imports page** — `GET /imports` omits a finished sync with outcome `nothing_to_sync` / `only_skipped_items`, still lists a `synced` one.
- [ ] **Weekly report** — `hangar_syncs` counts a `synced` run and not a no-op one.
- [ ] **Sync status untouched** — `GET /hangar/sync-status` still reports the latest run, no-op or not.

## Key files

| File | Role |
|------|------|
| `app/lib/hangar_sync.rb` | Decides the outcome, writes it to `output` |
| `app/models/import.rb` | The scope |
| `app/controllers/api/v1/imports_controller.rb` | User imports list |
| `app/lib/admin_weekly_report.rb` | `hangar_syncs` metric |

## Not in scope (deferred)
- **Admin maintenance imports page** — still lists no-op runs; admins use it to debug what a sync received.

## Discovery Log

- **2026-10-11** The sync status endpoint reads the latest `Imports::HangarSync` back to show the result card, so the row cannot be deleted. The user list payload carries no `output`, so the page cannot tell runs apart on its own.

## Progress
- [x] Phase 1
- [x] Phase 2
