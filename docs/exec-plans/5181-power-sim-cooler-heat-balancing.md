# Power sim: port the cooler heat-balancing and refinement passes

Working plan for #5181. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`allocatePower` produces the game's full default distribution: coolers sized against heat, the heat balance refined, and the cooler split chosen to minimise signatures. Sustained DPS, cooling and EM/IR are computed from that result.

## Open questions
- None blocking.

## What changed

### Phase 1 — Align the base and fill passes
1. Base pass criticals, in this order. SCM: lifeSupport, miningLaser, salvage, emp, 1 weapon segment, shield, radar, engine. NAV: lifeSupport, miningLaser, salvage, qdrive, radar, engine. Coolers, the QED and the beams get no base segment.
2. Fill pass. SCM: miningLaser, salvage, weapons to cap, shield, radar, engine. NAV: miningLaser, salvage, engine.
3. The override path (pinned per-port targets) keeps today's behaviour.

### Phase 2 — Heat model shared with the allocator
1. A heat-generation function over `{perPort, perFamily}`: every family's segments except weapons and shields, plus shields per port, plus `min(weapon segments, raw weapon draw)`, plus the extra heat from shield, life support, radar and QD (`seg × modifier`).
2. Cooler output is `rated × seg/units × modifier(seg)`, and only when `seg ≥ floor`.
3. `computeHeat` uses the same functions, so the display matches the allocator. Tractor/towing beams now count toward heat, and weapons count their raw draw.

### Phase 3 — Cooler passes
1. First cooler, before the fill: the smallest segment count from `floor` up whose cooling covers the heat of a projected fill.
2. Other coolers (SCM): add blocks until generation ≥ heat.
3. Balance loop (at most 200 iterations). While under-cooled: bring any cooler up to its floor, else shed radar/shield, else shed from the priority list. While over-cooled: trim the first cooler, else add engine segments within the headroom, else trade a radar/shield segment for engine segments when that uses more power and stays cooled.
4. Life support top-up (SCM), stopping as soon as it would over-heat.
5. Cooler split: with two or more coolers, keep the total and pick the split that covers the heat at the lowest `EM + coolingRatio × IR`.

### Phase 4 — Specs and wire-through
1. Specs for each pass in `powerSim.spec.ts`, and integration specs in `useLoadoutSim.spec.ts`.
2. Check sustained DPS, cooling and EM/IR against the reference tools on a few ships (manual).
3. Update the "Status of the port" section in `docs/findings/loadout-stat-formulas.md` and document the passes.

## Intent Verification

- [x] **Coolers balanced**: a ship whose coolers are under-powered after the fill gets cooler segments until cooling ≥ heat (spec).
- [x] **Refinement**: the leftover segments go to engines / life support within the cooling headroom (spec).
- [x] **Cooler split**: the multi-cooler split picks the lowest signature that still covers the heat (spec).
- [x] **Stats follow**: sustained DPS, cooling ratio and EM/IR reflect the new allocation.
- [x] **Overrides intact**: user pip overrides behave as before.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/composables/powerSim.ts` | Allocation engine |
| `app/frontend/frontend/composables/useLoadoutSim.ts` | Port construction, heat/EM, `simulateLoadoutPower` |
| `docs/findings/loadout-stat-formulas.md` | Formula record |

## Not in scope (deferred)
- **Armor signal modifiers** in the cooler-split score. We have no armor signature data, so both weights are 1.
- **`initialPowerAllocation`**: vehicles that ship a fixed default distribution.

## Discovery Log

- **2026-09-29** Compared on 4.10.1-live.12660092: Asgard SCM/NAV, Gladius SCM/NAV and Hammerhead SCM match pip for pip, cooling % included. Hammerhead NAV matches once its radar floor is 3; our data (and the game file) give 1.
- **2026-09-29** Decoded the full default pipeline. It differs from the recorded base/fill passes too: coolers, the QED and the beams have no base segment, and NAV fills only engines.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
