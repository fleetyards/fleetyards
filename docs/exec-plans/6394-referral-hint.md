# Referral code for people who don't play yet

Working plan for #6394. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Show the RSI referral code where people without an RSI account land, and give it a page of its own at `/enlist`.

## Phases

### Phase 1 — Shared hint
1. `RSI_REFERRAL_CODE` and `RSI_ENLIST_URL` in `utils/rsiReferral.ts`.
2. `ReferralHint` replaces the support modal's inline line; `texts.support.code` becomes `texts.referral.hint` with the 50,000 UEC amount.

### Phase 2 — Placements
1. Ship page: under the store/hangar buttons, signed-out only.
2. Landing sign-up section: under the login row, signed-out only.

### Phase 3 — `/enlist`
1. Frontend page with the code, a copy button, three steps and the RSI link; footer link.
2. Rails route and `base#enlist` action for the server-rendered title and description.

## Intent Verification

- [ ] **Signed out**: a ship page and the landing page's sign-up section show the hint; the code opens RSI's enlist page with the code.
- [ ] **Signed in**: neither shows the hint.
- [ ] **Enlist page**: copy puts the code on the clipboard; the button opens RSI's enlist page; the link preview shows the page title and description.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/utils/rsiReferral.ts` | The code and enlist URL |
| `app/frontend/frontend/components/ReferralHint/index.vue` | Shared one-line hint |
| `app/frontend/frontend/pages/enlist.vue` | `/enlist` |
| `app/controllers/frontend/base_controller.rb` | `enlist` meta |

## Discovery Log

- **2026-11-18** CIG raised the new-player bonus from 5,000 to 50,000 UEC in 2025, paid with the first game package; the old copy still said 5,000.
