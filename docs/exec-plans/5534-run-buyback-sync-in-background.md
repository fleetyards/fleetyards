# Run the whole buy-back sync in the background

Working plan for #5534. Decisions live in the issue body. Deleted before the PR merges.

Stacked on `feat/hangar-sync-background` (#5532): it reuses `useHangarSync`, the progress card and the plain `useRsiPageReport`. The PR targets that branch until #5532 merges.

## Goal

Reading the buy-back list, submitting it and reading prices runs as one run that outlives the modal, in the same way the hangar sync does.

## Open questions

None.

## What changed

### Phase 1 — One RSI rate limiter
1. `lib/RsiRateLimiter.ts`: export a shared app-wide limiter next to `createRsiRateLimiter`.
2. `useHangarSync` and the buy-back run take slots from it; `useBuybackDetailsSync` gets it instead of a `waitForSlot` passed in by the modal.
3. Drop the cross-sync start guards: `hangarSyncRunning` in the buy-back modal, `buybackDetailsRunning` in the hangar modal, and their texts (`texts.syncExtension.buybackDetailsRunning`, the buy-back modal's use of `texts.syncExtension.alreadyRunning`). The hangar modal keeps `hangarStore.syncRunning`: that guards a server run, not RSI.

### Phase 2 — `useBuybackSync` composable
1. Module-level state: status (`idle | fetching | submitting | finished | unsupported | failed`), current page, buy-backs read, result, extension capabilities captured at start.
2. Moves `start`, `fetchPage`, `handlePage`, `submit` and `fail` out of the modal. `submit` calls the plain `syncRsiBuybacks` and starts the price pass from `useBuybackDetailsSync`.
3. `cancel` (only while fetching), `reset` (when the modal closes on a run that is over), and a forced reset on sign-out (the details pass already discards on sign-out).
4. A run-id guard so late extension replies and timers of a cancelled or reset run do nothing.

### Phase 3 — Modal
1. The modal reads the composable. Opening on a running or unseen run shows it; closing clears a run that is over.
2. Closing mid-read backgrounds the run: drop `defineExpose({ dirty, dirtyText })` and `messages.buybackSync.closeWhileRunning` in all 7 locales.
3. Footer per the modal convention: bare Cancel while reading, then **Continue in background** while running, Close afterwards, Start/Retry as now.

### Phase 4 — Progress card
1. `BuybackDetailsSyncProgress` becomes the card for the whole run, with stages for list pages, saving and prices `done / total`. It shows **Show Details** to reopen the modal, and Cancel while RSI is read. It hides while the buy-back modal is open (a `buybackSyncModalOpen` flag, like `syncModalOpen`).
2. Its finish and incomplete toasts stay for the price pass. The list's own toasts come from the composable.

### Phase 5 — Translations and specs
1. New keys in all 7 locales: card label(s) for the list stage. Reuse `actions.syncExtension.runInBackground` and `actions.showDetails`.
2. A `useBuybackSync` spec, plus modal and card specs, following the hangar-sync ones in #5532.

## Intent Verification

- [ ] **Closing the buy-back modal while the list is read keeps reading it**, and the list is submitted once every page is read.
- [ ] **A partial list is never submitted**, whether the run is cancelled, a page is unrecognised, or the user signs out.
- [ ] **The card shows the run's stage** and reopens the modal, and the modal shows a run that ended in the background.
- [ ] **A hangar sync and a buy-back sync can run at once** and together stay at or under 60 RSI requests in any minute.
- [ ] **No sync's Start button is disabled because the other sync is reading RSI.**

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue` | The list crawl, submit and footer that move out |
| `app/frontend/frontend/composables/useBuybackDetailsSync.ts` | The price pass; already module-level |
| `app/frontend/frontend/components/Hangar/BuybackDetailsSyncProgress/index.vue` | Becomes the whole run's card |
| `app/frontend/frontend/lib/RsiRateLimiter.ts` | Gains the shared limiter |
| `app/frontend/frontend/composables/useHangarSync.ts` | Switches to the shared limiter |
| `app/frontend/frontend/components/Hangar/SyncBtn/Modal/index.vue` | Drops the buy-back start guard |
| `app/frontend/frontend/stores/hangar.ts` | `buybackSyncModalOpen` |

## Not in scope (deferred)

- Nothing yet.

## Discovery Log

- **2026-10-10** The buy-back strings `info` and `detailsInfo` said only the price part runs in the background; the background note moved to `info` in all 7 locales. `BuybackDetailsSyncProgress` is renamed `BuybackSyncProgress`, since it now shows the list stages too.
- **2026-10-10** Shared rate limit chosen over a queue; recorded in the issue body.
- **2026-10-10** Initial research and plan creation. The buy-back modal already passes `rateLimiter.take` to the price pass and checks `hangarSyncRunning` at submit time to avoid sharing the budget; one shared limiter makes both of those unnecessary.

## Progress
- [x] Phase 1 — One RSI rate limiter
- [x] Phase 2 — `useBuybackSync` composable
- [x] Phase 3 — Modal
- [x] Phase 4 — Progress card
- [x] Phase 5 — Translations and specs
