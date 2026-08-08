# Flight / Power / Heat simulation — erkul parity

Date: 2026-08-08. Branch: `feat/flight-power-heat-sim`.

## Why

Three erkul stats can't be matched with static-field lookups because they are
live functions of subsystems FleetYards doesn't simulate. This project builds
those subsystems. Each was individually spiked and confirmed sim-blocked
(see `erkul-data-gaps.md §1, §6, §8`).

| Unlocks | Needs |
|---|---|
| **§1** Sustained DPS at the *default* power distribution (we ship a max-power approximation today) | Power sim |
| **§6** Emitted **EM** signature | Power sim |
| **§6** Emitted **IR** signature | Power + Heat sim |
| **§3** Per-weapon overheat state ("NO OVERHEAT") | Heat sim |
| **§8** Flight boost (boosted SCM, boost regen, boost delay) | IFCS/flight sim |

## Source of truth

erkul's client-side calc engine, reverse-engineered from its JS bundle:
`main-OLN2ALGO.js` + `chunk-FWWRRMGF.js` (~69 KB, the calc). Decode each needed
function from there; validate our port against erkul's live numbers on a
reference ship (**Anvil Asgard**, data `4.9.0-live.12344265`).

### Already decoded (this project inherits)

- **Sustained cycle** `Io(regen, alpha, fireRateHz, powerRatio)` — pool =
  `round(maxAmmoLoad × powerRatio)`, regen = `maxRegenPerSec × powerRatio`,
  cycle = `regenerationCooldown + pool/regen + pool/fireRateHz`,
  `dpsSustain = pool × alpha / cycle`. Tuning multipliers `de` all = 1.
- **Weapon-power ratio** `Mo` → `poolRatio = min(1, selected / consumption)`,
  `weaponPowerRatio = min(1, poolSize / consumption)`. `U` = selected/enabled
  segments; `ue` = `ceil(Σ z(weapon).units)`; `z` = weapon Power draw from
  `resource.states[Online].flows.consumes[Power].units`; `Ot` = ship weapon
  pool (`vehicle.powerPools.pools[Fixed,WeaponGun].poolSize`).
- **Signatures** `Ao/Ro/dr/pr` — `signature = {em, ir, crossSection:{x,y,z},
  armorModifier, sources[]}`. `Ro` = per-port `emNominal/irNominal` from each
  item's `resource.states[Online].signature.{em,ir}.nominal`. `dr` (EM) sums
  per-port nominal × **active power segments** × power-range modifier × armor EM
  mult. `pr` (IR) = `Σ irNominal × (activeSegments/units) × modifier ×
  ship.coolingRatio × armor IR mult`. `CS = max(vehicle.crossSection.{x,y,z}) ×
  armor CS mult` (already clean — could ship standalone).

### Still to decode (per phase)

- **Power:** power-plant segment output `Lt` (`produces[Power, powerSegment]`);
  full segment **distribution** across families (weapons/shields/thrusters/…),
  the **default allocation** (pips), per-component `powerRanges` modifier curve,
  `activeSegments` per component, `te`/`fr`/`Rn` helpers referenced in `dr`.
- **Heat:** `coolingRatio` computation, heat `sources`, cooler aggregation,
  overheat cycle (`Ie`/`Lo` for ballistic already partly seen).
- **IFCS:** afterburner `capacitorMax`, `capacitorRegenPerSec`, NAV/SCM
  `regenCurvePoints`, `regenDelayAfterUse`, base SCM speed, boost speed
  multipliers; resolve the flight-controller from its slot.

## Architecture

- **Ruby (parse):** extend `items_parser`/`models_parser` to capture the raw
  inputs (power-plant segment output, per-component power draw + power ranges,
  cooler rates + per-component heat, flight-controller afterburner params, IFCS
  SCM). Ship-level aggregates become `Model` columns (migrations) where erkul
  reads them ship-wide.
- **TS (simulate):** a shared `useLoadoutSim` composable that mirrors erkul's
  engine — takes the parsed loadout, runs the power → heat → flight passes, and
  returns `{power: {perPortRatio, poolRatio, weaponPowerRatio}, heat:
  {coolingRatio, perWeaponOverheat}, signature: {em, ir, cs}, flight: {scm,
  boostFwd, boostBack, boostRegenS, boostDelayS}}`.
- **Wire:** `useLoadoutStats` (sustained DPS uses the real per-weapon ratio),
  Combat/Survivability/Flight cards, and per-weapon rows consume the sim.

## Phases

Each phase: **decode → parse → build the sim pass → wire displays → validate vs
erkul on the Asgard.** Land each as its own PR.

### Phase 1 — Power allocation (foundation)
Unlocks §1-exact + §6-EM. Biggest leverage; the sim's core.
1. Decode `Lt`, the family distribution + default allocation, `powerRanges`,
   `activeSegments`, and the helpers `dr` calls (`te`, `fr`, `Rn`).
2. Parse power-plant segment output; per-component Power draw + `powerRanges`
   (weapons have draw; add coolers/shields/thrusters/etc.); default allocation.
3. Build the power pass: total segments → distribute by default pips → per-
   component `activeSegments` + `poolRatio`/`weaponPowerRatio`.
4. Wire: replace the max-power `weaponPowerRatio` in `useLoadoutStats` with the
   real default `poolRatio`; expose per-port EM inputs.
5. Validate: Asgard sustained → erkul's default figure (the old "1 835"
   target, re-confirmed on current data).

### Phase 2 — Heat
Unlocks §6-IR + §3 overheat.
1. Decode `coolingRatio`, heat sources, `Ie`/overheat cycle.
2. Parse cooler rates + per-component heat (weapon overheat params already
   parsed).
3. Build the heat pass → `coolingRatio` + per-weapon overheat.
4. Wire: emitted IR (with Phase-1 power inputs → full §6), per-weapon overheat.
5. Validate: Asgard emitted IR/EM vs erkul.

### Phase 3 — IFCS / flight
Unlocks §8.
1. Decode afterburner capacitor/regen curves, base SCM, boost multipliers.
2. Parse flight-controller afterburner params + IFCS SCM (new `Model` metrics).
3. Build the flight pass → boosted fwd/back, boost regen time, boost delay.
4. Wire: a Flight card (or extend metrics) with the boost stats.
5. Validate: Asgard SCM/boost/regen/delay vs erkul.

## Data-parsing inventory

| Input | Source | Status |
|---|---|---|
| Weapon Power draw | `resource.states[Online].consumes[Power]` | ✅ (`power_consumption`) |
| Ship weapon pool size | `powerPools[Fixed,WeaponGun].poolSize` | ✅ (`weapon_pool_size`) |
| Power-plant segment output | `resource.states[Online].produces[Power,powerSegment]` | ❌ |
| Per-component Power draw (non-weapon) | same `consumes[Power]` path | ❌ |
| Per-component `powerRanges` modifier | component params | ❌ |
| Default power allocation / pips | vehicle `initialPowerAllocation` / global default | ❌ (needs decode) |
| Component EM/IR nominal | `resource.states[Online].signature` | ❌ |
| Ship cross-section | `crossSectionParams.SSCSignatureSystemManualCrossSectionParams.crossSection` | ❌ (clean) |
| Cooler cooling rate | cooler params | ✅ (`coolingRate`) |
| Weapon overheat params | `SWeaponSimplifiedHeatParams` | ✅ (`heat`) |
| Per-component heat | component params | ❌ |
| Flight-controller afterburner | `controller_flight_*` afterburner params | ❌ |
| Base SCM speed | IFCS (currently RSI-sourced) | ❌ (needs decode) |

## Decode log — Phase 1 (power allocation)

Findings from `chunk-FWWRRMGF.js` (2026-08-08):

- **Power-plant output:** `Lt(e)` = `resource.states[Online].flows[generate].
  produces[Power, unitKind=powerSegment].units`. Total available segments = Σ
  over powered-on plants.
- **The default allocation is an ALGORITHM, not a data field.** The Asgard has
  no `initialPowerAllocation`; erkul computes the distribution with `co(e, mode,
  …)` — a multi-pass greedy allocator over per-family buckets `$n = {weapon,
  engine, shield, qdrive, radar, lifeSupport, coolers, qed, emp, miningLaser,
  salvage, tractorBeam, towingbeam}`:
  1. `Zn` — base/minimum per family in priority order (SCM: lifeSupport →
     miningLaser → salvage → emp → weapon(1) → shield → radar → engine …; NAV
     swaps qdrive in for weapon/shield/emp).
  2. `Jn` — fill: weapon up to `min(weaponConsumptionPoints, poolSize)`, then
     shield / radar / engine.
  3. `ft` — cooler-balancing loop (≤200 iters): add cooler segments until
     cooling ≥ heat generation.
  4. `Ct` / `rt` — cooler refinement + remaining distribution.
  Per-mode (SCM vs NAV); `initialPowerAllocation` short-circuits it when present.
- Helpers to port: `Xn, Zn, Jn, ft, it, Ct, rt, tt, W, $, nt, et, D, Rt, me, yt,
  X, fo` + the `$n` family model.

### ⚠️ Power ↔ heat are coupled

`ft` balances cooler segments against **heat generation vs cooling**, so the
power allocation depends on the heat model. Phases 1 and 2 can't be fully
independent — either build the heat pass alongside Phase 1, or Phase 1 uses a
simplified cooler allocation (all coolers on) and Phase 2 refines it. **Revised
approach:** treat "power + heat" as one combined phase; ship flight (IFCS)
separately as it's the only truly independent piece.

## Risks

- **Faithfulness:** erkul's engine is intricate (power-range curves, per-mode
  regen curves, default-pip assumptions). Exact parity is the goal but some
  sub-models may need approximation; each phase validates against erkul and
  documents any gap.
- **Scope:** this is multi-session. Ship phase-by-phase; each PR leaves the app
  in a better, validated state.
- **Default allocation unknown:** the default pip distribution (erkul's
  `selected`) is the one input not yet located in the game files — Phase 1 must
  pin it down (decode from erkul, or reverse-fit against the Asgard).
