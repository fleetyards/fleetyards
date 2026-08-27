# Admin Import Notifications

Five of the recurring loaders report every run into the admin notification center through `AdminReport`: paints, modules, loaner, UEX prices, UEX commodities. The ship matrix import and the sc_data loaders do not, and a failed import of any kind is only visible as a row in the imports list and a cable broadcast nobody was watching — the center, which exists so an operator can find out afterwards what happened overnight, never hears about either.

## What is missing

| Run | Record | Today | Plan |
|---|---|---|---|
| `Loaders::ModelsJob` (ship matrix) | `Imports::ModelsImport` | cable only | `ship_matrix_import` report per run |
| `Loaders::ScData::AllJob` | `Imports::ScData::AllImport` | cable only, stats on the import | `sc_data_import` report per run |
| Any import that fails | every `Import` | cable only | `import_run` at error severity |
| Any admin import that finishes without its own report | `Imports::ModelImport`, `Imports::ScData::{Models,Model}Import` | cable only | `import_run` at info severity |
| A user's hangar import or sync | `Imports::HangarImport`, `Imports::HangarSync` | cable only | stays out — see D2 |

## Decisions

### D1 — One generic type, severity tells the outcome

`import_run` covers both the finished and the failed case rather than a type per outcome. The center already filters by severity, and a reader looking for "what did the imports do last night" wants one filter, not two. The two named types stay separate because they carry a report body, not a status line.

### D2 — A user's import is not admin news

`Imports::HangarImport` and `Imports::HangarSync` belong to a user and run whenever that user presses sync. Reporting them would put thousands of rows a week into every admin's inbox, and the user already gets `hangar_sync_finished` in their own center. The gate is `user_id.present?`, not a type list, so a user-owned import added later is excluded by default.

### D3 — A job that reports its own run silences the generic one

Otherwise every paints run lands twice: once as the report with the missing-model list, once as "Paints Import finished". The import knows which types those are, and the generic notification skips them on success — but never on failure, because a report that never ran is exactly what the failure notification is for.

### D4 — Actionable means "a catalogue came back empty"

`AdminReport` opens a GitHub issue when a report is actionable, so the bar is a run that needs a human. For sc_data that is a loader whose counts are all zero — the failure mode that left Commodity and Equipment empty for a week. For the ship matrix, a run that touches nothing is normal (the matrix rarely changes), so it never marks itself actionable; a broken run raises, and D1 covers it.

---

## Progress

- [x] Phase 1 — Notification types
- [x] Phase 2 — Ship matrix report
- [x] Phase 3 — sc_data report
- [x] Phase 4 — Generic import notifications
- [x] Phase 5 — Tests, lint, schema

---

## Phase 1: Notification types

`AdminNotification` gains three enum values and their `TYPES` entries:

- `ship_matrix_import` — access `[:models]`, 30 days
- `sc_data_import` — access `[:models]`, 30 days
- `import_run` — access `[:imports]`, 30 days

Plus `labels.adminNotifications.types.*` in `en`, and a regenerated admin schema (the enum component reads the model).

## Phase 2: Ship matrix report

`Loaders::ModelsJob` reports what the run changed. `Rsi::ModelsLoader#all` returns nothing countable, so the job measures either side of it: models created since the run started, and models updated but not created. New models are listed by name — that is the part worth reading.

## Phase 3: sc_data report

`Loaders::ScData::AllJob` already collects `BaseLoader.all`, a hash of per-loader `{created, updated, unchanged}` counts, and stores it on the import. The same hash becomes the report body, and a loader with three zeroes makes the run actionable (D4).

## Phase 4: Generic import notifications

`Import#notify_admin` keeps its cable broadcast and adds a center notification, gated by D2 and D3. Failure carries `info` (the exception message) as the body at error severity.

## Phase 5: Tests, lint, schema

Job tests for both reports, model tests for the gates, `standardrb`, `./bin/generate-schema`.

## Not in scope

- **RSI news and YouTube feeds** — one entry per run would be noise; they post to Discord and a failure raises
- **Per-model sc_data loads** (`Loaders::ScData::ModelJob`) — covered by the generic notification
- **Retiring `ImportsChannel`** — the live progress view still uses it

## Discovery Log

- **2026-08-27** `BaseLoader.all` hands back nil when nothing ran, which the
  existing job test stubs — the report has to render either way.
- **2026-08-27** Written after the notification center landed (#4562). `hangar_sync_finished` already exists on the user side and needed nothing.
