# Hangar Planner: put a held upgrade into a route without rebuilding it

Working plan for #6338. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A held CCU or buy-back upgrade goes into a route in one action, and editing a step keeps the steps after it that still connect.

## What changed

### Phase 1 — Chain logic
1. `Planner/chain.ts`: `reattach` (keep a tail that still connects, bridge a held step with a store upgrade, drop what no longer fits) and `spliceHeld` (insert a held upgrade after the last stop it can follow).
2. Specs for start, middle, ending on the target, and replacing store steps.

### Phase 2 — Route builder
1. Source switch, picks, insert and remove go through `reattach` instead of dropping the tail.
2. "Upgrades you hold that fit" list above the chain splices on pick.

### Phase 3 — Plan page suggestions
1. Panel listing unused held upgrades that make a complete route cheaper, with one-click apply through the acquisition update.
2. Translations for every locale.

## Intent Verification
- [ ] A held CCU put into the middle of a saved route keeps every step before and after that still connects
- [ ] A store stop goes in front only when the previous stop is not the CCU's start
- [ ] Changing a step's source does not delete later steps
- [ ] A fitting unused CCU shows on the plan page with its saving and applies in one click

## Key files
| File | Role |
|------|------|
| `app/frontend/frontend/components/Hangar/Planner/chain.ts` | Splice and reattach |
| `app/frontend/frontend/components/Hangar/Planner/ShipPanel/RouteView/index.vue` | Route builder |
| `app/frontend/frontend/components/Hangar/Planner/UpgradeFits/index.vue` | Plan page suggestions |

## Discovery Log
- **2026-11-16** Add stop is store-only and resets later held steps; setSource, pickHeld and store picks call dropAfter. The acquisition update replaces all steps when `steps` is sent, so applying a splice needs no backend change.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
