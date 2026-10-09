# Hangar sync: let the server decide when a sync has nothing to do

Working plan for #5528. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The sync run, not the modal, decides that a sync has nothing to do, and the modal shows the outcome the run reports.

## Open questions
- None.

## What changed

### Phase 1 — Server
1. `HangarSync#run_with_import`: before syncing, check for a syncable item: a ship, component or upgrade, a skin when `sync_paints?`, or flair when `sync_hangar_flair?`. If there is none, skip every sync step (vehicles, components, upgrades, pledge items), store an all-empty output with `outcome`, finish, broadcast, and send no notification. Otherwise set `outcome: "synced"`.
2. New `HangarSyncOutcomeEnum` component, and an optional `outcome` on `HangarSyncResult` (shared with cable).
3. Controller: return 400 only when `items` is missing; accept `[]`.
4. Tests: lib (`test/loaders/hangar_sync_test.rb`) for both no-op outcomes, including that stored paints are kept with the toggle on and the list empty, unmatched ships are left alone, and no notification is sent; integration test for `items: []`; asyncapi payload.
5. Regenerate `swagger/v1/schema.yaml`, `asyncapi/cable/v1/schema.yaml` and the clients.

### Phase 2 — Client
1. Modal: drop `syncablePledges` and the early return in `finishSync`; always submit. On a finished result whose `outcome` is a no-op, show `nothingToSync` / `onlySkippedItems` instead of `success`, and hide the support prompt.
2. Specs: rewrite the two "submits nothing" specs to submit, then feed back a no-op result.

## Intent Verification

- [x] An empty `items` list returns 200 and finishes as `nothing_to_sync`.
- [x] Only turned-off paints and flair finish as `only_skipped_items` with nothing touched, under every unmatched-vehicles action.
- [x] The stored paints and flair survive an empty run even with both toggles on.
- [x] The modal has no kind filter and shows the server's outcome; no support prompt after a no-op.

## Key files

| File | Role |
|------|------|
| `app/lib/hangar_sync.rb` | Sync run; where the no-op is decided |
| `app/controllers/api/v1/hangars_controller.rb` | `sync_rsi_hangar` empty-list guard |
| `app/api_components/v1/schemas/hangar/hangar_sync_result.rb` | Result schema (v1 + cable) |
| `app/frontend/frontend/components/Hangar/SyncBtn/Modal/index.vue` | Client guard to remove; result handling |
| `test/loaders/hangar_sync_test.rb` | Lib tests |
| `test/integration/api/v1/hangar_sync_rsi_test.rb` | Endpoint tests + openapi path |

## Not in scope (deferred)
- None yet.

## Discovery Log

- **2026-10-09** Initial research. The server already treats a ship-less list safely for vehicles, but an empty list with a toggle on deletes every stored paint/flair (`HangarPledgeItems::Sync` deletes everything not in the list), and an empty run lists every purchased ship as unchanged and notifies.

## Progress
- [x] Phase 1
- [x] Phase 2
- **2026-10-09** Implemented. The outcome enum is not tagged for cable; the AsyncAPI writer follows the `$ref` from `HangarSyncResult`. One existing lib test relied on an empty list wiping stored paints; it now uses a ship-only list.
