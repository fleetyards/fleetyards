# Sync buy-back pledges via the sync extension

Working plan for #5461 (part of #2644). Decisions live in the issue body. Deleted before the PR merges.

## Goal
The hangar sync also reads the RSI buy-back list through the extension's `syncBuyback` action and keeps it per user, ready for the hangar planner.

## What changed

### Phase 1 — API
1. `buyback_pledges` table + `BuybackPledge` model (kind, name, upgraded, reclaimed_on, contained, image, upgrade from/to ship ids, to-SKU id), unique on `(user_id, rsi_pledge_id)`.
2. `BuybackPledges::Sync`: upsert the list, delete what is no longer listed, in one transaction.
3. `PUT /hangar/sync-rsi-buybacks` and `GET /hangar/buybacks`, components, integration tests, `bin/generate-schema`.

### Phase 2 — Sync modal
1. `RSIBuybackParser` + spec against a trimmed copy of the real page markup.
2. `fetchBuybacks` step after `fetchHangar`; `skipped` status for an extension without `syncBuyback`.
3. `syncBuybacks` toggle in the hangar store (persisted, on by default).
4. Labels in all seven locales.

## Intent Verification

- [x] **Full replace only** — a fetch that fails halfway submits nothing; rows survive.
- [x] **Old extension** — `500 Unknown Action` on `syncBuyback` marks the step skipped and the sync reads as finished.
- [x] **Isolation** — no hangar, fleet or stats scope reads `buyback_pledges`.

## Key files

| File | Role |
|------|------|
| `app/models/buyback_pledge.rb` | The row |
| `app/lib/buyback_pledges/sync.rb` | Replace a user's list |
| `app/controllers/api/v1/hangar_buybacks_controller.rb` | Index + sync |
| `app/frontend/frontend/lib/RSIBuybackParser.ts` | Page → items |
| `app/frontend/frontend/components/Hangar/SyncBtn/Modal/index.vue` | The fetch loop |

## Discovery Log

- **2026-10-07** Buy-back page markup: `section.available-pledges ul.pledges > li > article.pledge`. Title in `h1[title]` (an `upgraded` span is appended to the text, not the attribute), `dl` with "Reclaim Date" / "Contained". Packages link `/pledge/buyback/<id>`; upgrades carry `a.js-open-ship-upgrades[data-pledgeid][data-fromshipid][data-toshipid][data-toskuid]`. 10 per page; a page past the end renders no `article.pledge` and no empty-list marker. Availability is not in the markup (both the action and the "unavailable" block are rendered, CSS picks one).
- **2026-10-07** One real account has 130 pages, so a full buy-back read is ~2–3 minutes at the modal's 60 requests/minute.
- **2026-10-07** Not exercised end to end against RSI: that needs the unreleased extension build loaded in a browser on a running dev server. The modal spec drives the same message sequence.

## Progress
- [x] Phase 1
- [x] Phase 2
