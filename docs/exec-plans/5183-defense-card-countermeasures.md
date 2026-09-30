# Defense card: show countermeasures (decoy and noise)

Working plan for #5183. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The Defense card shows a ship's total decoy and noise ammo, and nothing for ships without countermeasures.

## What changed

### Phase 1 — Frontend only
1. `useCountermeasureStats` walks the hardpoint tree, classifies each countermeasure launcher by its item key (flare/decoy vs chaff/noise) and sums `typeData.maxAmmo` per kind.
2. `Models/DefenseMetrics` renders the totals as chips below armor; kinds with zero ammo are dropped, and the card also shows for a ship that only has countermeasures.
3. Labels in all seven locales.

## Intent Verification

- [x] **Totals per ship** — Asgard: 4 × 48 decoy = 192, 4 × 5 noise = 20 (dev DB).
- [x] **No zeros** — an empty kind is filtered; no countermeasures means no section.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/composables/useCountermeasureStats.ts` | Aggregation |
| `app/frontend/frontend/components/Models/DefenseMetrics/index.vue` | Card |

## Discovery Log

- **2026-09-30** Display names do not separate the kinds: `orig_m50_cml_flare` and `orig_cml_decoy_small` are named "Noise Launcher", some launchers have no name. Every one of the 188 countermeasure components in the dev DB has a key matching flare/decoy (95) or chaff/noise (93). `scKey` and `typeData.maxAmmo` are already on the hardpoint payload, so no backend change.

## Progress
- [x] Phase 1
