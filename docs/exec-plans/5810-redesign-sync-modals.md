# Redesign the hangar and buy-back sync modals

Working plan for #5810. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Both sync modals match their boards on the Claude Design canvas, in every state, on the modal frame from #5807.

## Open questions

- **Target group label and hint.** The group applies to every ship the sync touches, found ones too (`app/lib/hangar_sync.rb:658-664`), so the label "Group for the ships it finds" stays. Its hint is the file import's (`labels.imports.targetGroupHint`) and is wrong for the sync. Default: a sync hint of its own.
- **Failed state copy.** The sync job has no transaction (`app/lib/hangar_sync.rb:108-153`), so a failure can leave ships partly synced. Retry resubmits the whole list and matching makes it mostly idempotent. Default: say that some changes may already be in and that retrying is safe.
- **Hangar progress bar.** The total page count is unknown: the parser reads no pager (`lib/RSIHangarParser.ts`). Default: an indeterminate bar with the page counter. A filling bar needs a captured RSI page to check for a pager; that becomes its own issue.

## What changed

### Phase 1: Shared pieces
1. `Hangar/SyncSessionStatus`: a quiet row (status dot, "Signed in to RSI as …", recheck) when connected; a warning `Alert` with "Sign in" and "Check again" when not. Keep `sync-session-status`, `sync-session-recheck` and `sync-session-sign-in`.
2. `SyncExtensionLinks`: one row per store with its browser icon, name and an Add/Update link; keeps the compact variant for its other callers.
3. A step list (`Hangar/SyncSteps`): numbered or done/failed marker, label, detail, an optional determinate or indeterminate bar, and a slot for chips.
4. Result tiles: number plus label, in a grid.

### Phase 2: Hangar sync modal
1. Start view: session row, two short points, settings summary (ships not in RSI, not syncing) with a way to open settings, target group field.
2. Settings view: switch rows with hints, "Ships not in your RSI hangar" section.
3. `SyncResultPanel`: running as steps with chips and bars; finished as a success `Alert` plus tiles, with what was read folded away; unmatched items as a warning `Alert` plus collapsible groups; failed as a danger `Alert` plus steps. `SupportHint` stays on success.
4. Keep every data-test hook the specs and `HangarSyncModal.spec.ts` use.

### Phase 3: Buy-back sync modal
1. Start view: session row, three points, info `Alert` for the slower first sync.
2. Running: three steps (reading pages, saving, reading prices with its `done / total` bar).
3. Finished: success `Alert`, tiles, `SupportHint`.
4. Outdated extension: warning `Alert` plus the store rows.

### Phase 4: Copy
1. New keys in all seven locales, translated by hand; remove keys nothing reads any more.

### Phase 5: Tests and visual pages
1. Update the modal, result and buy-back specs for the new markup; keep the hooks.
2. Visual pages cover every state, including buy-back running and finished.

## Intent Verification

- [ ] **Every state matches its board**: compared against the canvas at desktop and phone width on `/visual-tests/sync-modal/` and `/visual-tests/buyback-sync-modal/`.
- [ ] **Notices are Base Alerts**: no toned panel or coloured status text left in either modal.
- [ ] **Progress bar per running step**: hangar reading and saving, buy-back reading, saving and prices.
- [ ] **Supporter hint on both successes.**
- [ ] **Store rows with icon and name.**
- [ ] **Copy in every locale**: no key missing in any of the seven.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Hangar/SyncBtn/Modal/index.vue` | Hangar sync modal: start, settings, footer |
| `app/frontend/frontend/components/Hangar/SyncBtn/Result/index.vue` | Progress and result panel |
| `app/frontend/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue` | Buy-back sync modal |
| `app/frontend/frontend/components/Hangar/SyncSessionStatus/index.vue` | RSI session row |
| `app/frontend/frontend/components/SyncExtensionLinks/index.vue` | Extension store links |
| `app/frontend/frontend/composables/useHangarSync.ts`, `useBuybackSync.ts`, `useBuybackDetailsSync.ts` | Run state the views read |
| `app/frontend/frontend/components/Hangar/SyncBtn/visual.vue`, `BuybackSyncBtn/visual.vue` | Visual-test pages |
| `test/playwright/e2e/HangarSyncModal.spec.ts` | E2E hooks to keep |

## Not in scope (deferred)

- **A filling hangar progress bar**: needs the RSI pager's markup from a real page capture. Becomes its own issue.
- **The progress cards outside the modal** (`SyncProgress`, `BuybackSyncProgress`): they keep their design.

## Discovery Log

- **2026-10-18** Initial research: the state machines of both modals, the data-test hooks the specs pin, the target group's real scope, the missing transaction, and the unknown page total.

## Progress
- [ ] Phase 1: Shared pieces
- [ ] Phase 2: Hangar sync modal
- [ ] Phase 3: Buy-back sync modal
- [ ] Phase 4: Copy
- [ ] Phase 5: Tests and visual pages
