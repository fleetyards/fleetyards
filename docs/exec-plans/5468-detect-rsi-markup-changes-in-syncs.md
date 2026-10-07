# Detect RSI markup changes in the hangar and buy-back syncs

Working plan for #5468. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A sync that meets a page it does not recognise stops without changing anything and tells the admins, instead of reading the page as the end of the list.

## Open questions

- None.

## What changed

### Phase 1 — Backend
1. `AdminNotification` type `rsi_markup_changed` (error, 30 days, `rsi-api-status` access, like the block notifications), with its label in all 7 locales.
2. `POST /api/v1/hangar/rsi-page-reports` (`hangar:write`): `RsiPageReportInput` `{page, check, pageNumber, extensionVersion}` with `RsiPageKindEnum` / `RsiPageCheckEnum`; answers 204 and raises the notification deduplicated by `page:check`. No HTML or pledge content is accepted.
3. `HangarSync#handle_unmatched_vehicles`: leave every vehicle where it is when the sync holds no ships.
4. Regenerate the OpenAPI and AsyncAPI schemas and the clients.

### Phase 2 — Parsers
1. `RSIHangarParser.extractPage` answers `page`, `end` or `unrecognised` (with the check that failed): only `.empty-list` / `.empy-list` is the end; no `.list-items`, entries without pledge ids, or items without a `.kind` are unrecognised.
2. `extractBuybackPage` adds the case it reads as the end today: no entries while the page still links to `/pledge/buyback/`.

### Phase 3 — Modals
1. Hangar and buy-back sync modals: an unrecognised page fails the sync with its own message and sends the report; nothing is submitted.
2. Message in all 7 locales.

## Intent Verification

- [ ] **No partial sync** — an unrecognised page 3 stops the hangar sync; nothing reaches `sync-rsi-hangar`
- [ ] **No empty buy-back sync from drift** — renamed entries stop the buy-back sync instead of deleting every buy-back
- [ ] **Admins hear about it** — one deduplicated admin notification per page and check, counting occurrences
- [ ] **Backstop** — a hangar sync without ships moves or deletes nothing

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/lib/RSIHangarParser.ts`, `RSIBuybackParser.ts` | Parsers |
| `app/frontend/frontend/components/Hangar/SyncBtn/Modal/index.vue`, `BuybackSyncBtn/Modal/index.vue` | Sync flows |
| `app/models/admin_notification.rb` | Notification types |
| `app/lib/hangar_sync.rb` | Unmatched-vehicles handling |

## Not in scope (deferred)

- None yet.

## Discovery Log

- **2026-10-07** Initial research. The hangar endpoint already refuses an empty item list; the live risks are a mid-run unrecognised page and a relabelled ship kind. The buy-back modal already fails on non-buy-back pages and unparseable entries; its gap is zero entries read as the end.

## Progress

- [ ] Phase 1 — Backend
- [ ] Phase 2 — Parsers
- [ ] Phase 3 — Modals
