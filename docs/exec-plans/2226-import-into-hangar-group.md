# Hangar imports: visible, cancellable, and aimed at a group

## Goal

A user can see their own hangar imports and RSI syncs, stop one that is taking
too long, and choose which hangar group the imported ships land in.

Resolves #2226.

## Context

Two paths put ships into a hangar, and they are built very differently.

| | `Imports::HangarImport` | `Imports::HangarSync` |
|---|---|---|
| Trigger | `PUT /hangar/import`, a JSON file | `PUT /hangar/sync-rsi-hangar`, items scraped by the browser extension |
| Runs | **inline in the web request** (`HangarImporter#run`) | `HangarSyncJob` on Sidekiq |
| Concurrency guard | none | 409 if one is `created`/`started` |
| User can see it | only the returned payload | `sync-rsi-hangar/status` poll + `hangar_sync_finished` notification |
| User can cancel it | no | no |

`Import` is an STI root with AASM `created / started / finished / failed` and no
cancel. The only stop-like affordance is `Import#cleanup!` — admin-only, and its
own comment says nothing reaches the running job. `FleetEvent` is the one model
in the codebase with a real AASM `cancel`, and it is the pattern this follows.

The `imports` browsable resource is admin-only (`Admin::Api::V1::ImportsController`).
There is no public `Import` resource at all. The jbuilder partials under
`app/views/api/v1/imports/` already exist, deliberately omit `user`/`admin_user`
and the blob URL, and are currently reachable from nothing.

### The blocker: every import lands on the wishlist

`hangar_importer.rb:61` reads:

```ruby
wanted: item[:wanted] || !item[:purchased] || true,
```

`wanted: true` is the **wishlist** flag (`Vehicle.purchased == where(wanted: false)`).
`Vehicle#reset_hangar_groups` is an `after_save` that destroys every task force
when the record is `wanted?`. So an import assigns `hangar_group_ids` at
`hangar_importer.rb:66` and the very next callback throws them away.

Proven against both formats with a throwaway test:

```
[modern] wanted=true groups=[]     # {wanted: false, groups: ["Main"]}
[legacy] wanted=true groups=[]     # {purchased: true, groups: ["Main"]}
```

Two separate faults stacked up:

- `!item[:purchased]` — the current export
  (`app/views/api/v1/vehicles/_export.jbuilder`) emits `wanted` and **no
  `purchased` key**, so this term is `!nil` → always true. Broken since the
  purchased flag was refactored out (#2559).
- `|| true` — added by 9806162c3 (2025-11-28) under the message *"import ships
  always into the hangar not the wishlist"*. The expression does the opposite of
  the message, and it made the fault unconditional rather than
  format-dependent.

Neither `test/loaders/hangar_importer_test.rb` nor
`test/integration/api/v1/hangar_import_test.rb` asserts anything about `wanted`
or `hangar_groups`, which is why it went unnoticed.

Round-tripping your own hangar export currently moves your whole hangar onto the
wishlist and drops every group assignment. The group feature is unimplementable
until this is fixed, so the fix is part of this work rather than a follow-up.

## Decisions

### D1 — The target group always wins when one is set

The import/sync dialog offers a single hangar group. When set, every ship the run
creates goes into that group and any per-item `groups` in the file are ignored.
When it is not set, the current behaviour stands: per-item `groups` are matched
by name against the user's groups.

An RSI sync carries no group data at all, so a target group is the only way it
can ever populate one — that is the case the issue was opened for. Honouring the
file only when the user expressed no preference keeps a plain re-import lossless.

### D2 — `wanted` follows the file and defaults to owned

```ruby
wanted: item[:wanted] || false
```

The `!item[:purchased]` term goes. An owned ship imports as owned, an explicit
wishlist entry stays on the wishlist, and a Fleetyards export round-trips
faithfully. This is what 9806162c3 was reaching for.

Legacy files carrying `purchased` and no `wanted` now import as owned, which is
right for the 134-of-165 majority in `test/fixtures/imports/export.json` and
wrong only for the 31 that were wishlist entries — a strictly better outcome
than today, where all 165 become wishlist entries.

### D3 — The file import moves to Sidekiq

`HangarImporter#run` currently blocks a Puma worker for the length of the import.
Nothing can cancel a synchronous call, so cancellation requires the move
regardless; that it also stops a 165-ship file from occupying a web worker is a
bonus.

`PUT /hangar/import` therefore stops returning the result and returns
`{id, status}` like the sync does. That is a **breaking response change** and
needs an `swagger/v1/oasdiff-ignore.txt` entry.

### D4 — Cancellation is cooperative, and the state flips immediately

`cancel` transitions `created → cancelled` and `started → cancelled` at once, so
the user gets an answer rather than a pending request, and it sets
`cancel_requested_at` in the same write.

The running job reads `cancel_requested_at` at a checkpoint every
`CANCEL_CHECK_INTERVAL` items — a single-column `pick`, not a `reload`, because
`reload` would drag the whole `import_data` YAML blob back from the database each
time. On seeing it, the loop stops, writes what it managed as `output`, and
returns **without** calling `finish!`.

The state, not the flag, is the thing the job must not fight: a run that
completes in the window between the transition and the next checkpoint would
call `finish!` from `cancelled` and raise `AASM::InvalidTransition`. The
finalizer checks for a cancel before transitioning.

A cancelled import keeps the ships it already created. Rolling back would mean
holding a transaction open for the whole run, and a half-imported hangar the user
can see and fix beats a run that silently undoes itself.

### D5 — A dead worker still cancels

If the Sidekiq process is gone, no checkpoint will ever fire, but the state has
already moved to `cancelled` — so the row stops claiming to be running and the
user is not stuck behind the 409 guard. This is the same outcome `cleanup!` gives
an admin, reached without one.

### D6 — The target group is a column, not a key in `input`

`imports.hangar_group_id`, uuid, FK with `on_delete: :nullify`. `input` is
already the sync's item payload and `import_data` is the file import's, so
neither is a shared home. A column gives `belongs_to :hangar_group, optional: true`,
which is what renders the group's name in the history view, and a deleted group
nullifies instead of dangling.

Type-specific columns are already how this table works — `version` is sc_data
only, `import_data` is `HangarImport` only.

### D7 — The public imports resource is scoped by `user_id`, not by a type list

`Import.where(user_id: current_resource_owner.id)` reaches exactly
`Imports::HangarImport` and `Imports::HangarSync` today, because every other
subclass is system- or admin-owned. A user-owned type added later is included by
default, which is the behaviour we want, and it mirrors the `user_id.present?`
gate `Import#report_run` already uses to keep user imports out of the admin
notification center.

### D8 — The history view polls; no new cable channel

Revised during implementation. A `UserImportsChannel` would need its own
asyncapi components and a subscription whose death is invisible — the failure
mode in `cable-badge-masks-dead-subscription`, where a poll on one element hides
a dead socket on another. The imports view instead refetches while any import it
is showing is still running, and stops when none is.

`HangarSyncChannel` is untouched, so the existing sync modal keeps its live
updates; it gains a `cancelled` status alongside `finished` and `failed`.

The two missing per-type partials (`api/v1/imports/hangar_imports/_hangar_import.jbuilder`
and `.../hangar_syncs/_hangar_sync.jbuilder`) are added anyway: `Import#to_jbuilder_hash`
resolves a template from the class name, and both subclasses had none because
`notify_admin` is a no-op on each, so nothing had ever called it.

### D9 — The user-facing views get their own partial

`api/v1/imports/_base.jbuilder` is the payload `ImportsChannel` broadcasts to
admins, and the admin store reads `input` off it (`isImporting(types, inputMatch)`),
so it cannot be trimmed. But `input` is the whole scraped pledge list and
`import_data` the whole uploaded file — a page of either would dwarf the rest of
a history list and hands the owner back nothing they did not send.

`_user_import.jbuilder` is therefore separate and narrower, and `_base` keeps its
shape.

## Phases

- [x] Phase 1 — Migration, `Import` cancel, importer group + `wanted` fix
- [x] Phase 2 — `HangarImportJob`, controller returns a submit result
- [x] Phase 3 — Public `api/v1/imports` resource (index / show / cancel)
- [ ] Phase 4 — Frontend: group picker, history page, live status, cancel
- [ ] Phase 5 — Locales, lint, frontend tests

### Phase 1

- Migration: `cancelled_at:datetime`, `cancel_requested_at:datetime`,
  `hangar_group_id:uuid` + FK nullify + index.
- `Import`: `state :cancelled`, `event :cancel` from `created`/`started`,
  `belongs_to :hangar_group, optional: true`, ransack allowlist entries.
- `HangarImporter`: target-group override (D1), `wanted` fix (D2), checkpoint +
  cancel finalizer (D4).
- Regression tests for `wanted` and group assignment — the ones whose absence hid
  this.

### Phase 2

- `HangarImportJob`, `sidekiq_options queue: "default"`, bails unless `created?`.
- `HangarsController#import` enqueues and renders `{id, status}`; add the same
  409 already-running guard the sync has.
- `ImportSubmitResult` component; `oasdiff-ignore.txt` entry for the changed 200.

### Phase 3

- `Api::V1::ImportsController` — `index`, `show`, `cancel`.
- `ImportPolicy` (owner only) + relation scope on `user_id`.
- Routes under `config/routes/api/`.
- Components: `Import`, `Imports`, `ImportQuery`, `ImportStatusEnum`,
  `ImportTypeEnum` in `v1/schemas/` — note the admin `ImportTypeEnum` is a
  hardcoded list and the public one must carry only the two user-facing types.
- `_base.jbuilder` gains `hangarGroup`, `cancelledAt`.

### Phase 4

- `HangarGroupsSelect` with `:multiple="false"` in the import dialog and the sync
  modal.
- Imports history page + detail under the user's account area, refetching while
  anything on it is still running.
- Cancel button on a running import.
- The import button stops awaiting a result and hands off to the history view.

### Phase 5

- All 7 locales by hand (`de en es fr it zh-CN zh-TW`) — Crowdin is not wired up
  and `enableFallback` hides a missing key rather than failing.
- `pnpm lint:fix`, `pnpm lint:ts`, Vitest where a component carries logic.

## Not in scope

- **Progress percentages.** The checkpoint already knows the index, so a
  `processed / total` broadcast is cheap to add later; it is not needed for
  cancel to work and it multiplies the cable traffic per run.
- **Retrying a failed import.** Re-uploading the file is the current answer and
  nobody has asked for better.
- **Admin-side cancel.** `cleanup!` covers the admin case and its semantics
  (write off a stuck row) differ from a user stopping their own run.
- **Undoing a cancelled import's ships.** See D4.

## Discovery Log

- **2026-09-11** `wanted` fault proven empirically on both export formats before
  any change; both faults predate this work and neither is covered by a test.
- **2026-09-11** `test/fixtures/imports/export.json` is the *legacy* format
  (`purchased`, `customName`, no `wanted`); `test/fixtures/files/hangar_import.json`
  is the current one. Tests that only use the former miss modern-format bugs.
- **2026-09-11** `Imports::HangarImport` and `Imports::HangarSync` have no
  jbuilder partial of their own — `notify_admin` is a no-op on both, so the
  missing template has never been reached.
