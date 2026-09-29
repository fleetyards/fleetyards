# Mobile layout pass: compare, ship detail, text and tap-target sizes

Working plan for #5236. Decisions live in the issue body. Deleted before the PR merges.

## Goal

No text under 11px and no touch control under 32px on the ship, compare and catalogue pages, plus the logged-in pages the audit covers.

## Open questions

- None.

## What changed

Compare's two-ship layout and the compact ship header landed in #5244; the 32px touch mixin and the first four 11px labels in #5247.

### Phase 1 — Text floor and touch areas

1. Every text `font-size` under 11px on the compare, ship detail and catalogue pages raised to 11px. Glyphs (chevrons, ▲/▼ markers, the icon-only power column label) stay as they are.
2. `touch-tap-target` on the compare section toggles and the add-on steppers.

### Phase 2 — Logged-in audit

1. At 390px, signed in as a throwaway local user: hangar management, fleet events, contracts, tours.
2. Findings into the issue; fix what is text or touch size in this PR.

## Intent Verification

- [ ] **No text under 11px** on ship detail, compare and catalogue at 390px, measured in the browser.
- [ ] **No touch control under 32px** there on a coarse pointer.
- [ ] **Nothing overflows** the metric tiles, compare cells or row tags at the new size.
- [ ] **Audit findings recorded** on the issue.

## Key files

| File                                                               | Role                                             |
| ------------------------------------------------------------------ | ------------------------------------------------ |
| `app/frontend/shared/components/metricsCard.scss`                  | metric labels on ship detail and catalogue cards |
| `app/frontend/frontend/components/Compare/Models/Table/index.scss` | compare table                                    |
| `app/frontend/shared/components/RowListItem/index.scss`            | catalogue rows                                   |
| `app/frontend/stylesheets/variables.scss`                          | `touch-tap-target`                               |

## Not in scope (deferred)

- **Public hangar cold load** — its own PR, per the issue.

## Discovery Log

- **2026-09-29** #5244 and #5247 had already shipped compare, the ship header and most touch targets; their issue boxes were unticked. 77 sub-11px declarations in the frontend; the fleet and payout ones wait for the audit.

## Progress

- [x] Phase 1
- [ ] Phase 2
