# Interactive power-distribution (pip) UI

Date: 2026-08-09. Branch: `feat/power-distribution-ui` (off `feat/sim-power-heat`).

## Goal

An erkul-style **power-distribution control** on the ship loadout page: the user
allocates power segments across component families (weapons / shields / engines
/ …) and sees **DPS, sustained DPS, and signatures recompute live**. This is the
headline interactive feature that makes FleetYards a *calculator*, not just a
stats display.

## Dependencies

- **`powerSim.ts`** — the allocation core (`co()` port: primitives + Zn/Jn
  passes + `weaponPoolRatio`), already built + unit-tested on
  `feat/sim-power-heat` (PR #4266).
- **Per-component power parsing** — `power_consumption` + `power_ranges` on all
  power-drawing components (also #4266).
- **Still needed** (built in this feature): engine/lifeSupport power draw
  (coverage gap), the exact non-weapon block sizing, and — for signatures — the
  heat model (`coolingRatio`).

See `flight-power-heat-sim.md` for the full decode of erkul's engine.

## Architecture

- **`useLoadoutSim(hardpoints, model, overrides?)`** — the integration layer:
  1. Build `PowerPort[]` from the loadout — per family (`item_type` → family:
     WeaponGun→weapon, Shield→shield, Cooler→coolers, Radar→radar,
     QuantumDrive→qdrive, EMP→emp, + engine/lifeSupport once parsed), with the
     weapon pool as `poolSize` size-1 blocks (`consumption` enabled).
  2. `totalSegments = Σ power_base` over powered plants.
  3. Run `allocatePower(ports, totalSegments, {…, overrides})` → per-family
     segments + per-family power ratios.
  4. Return `{ perFamily, weaponPoolRatio, remaining, byPort }`, reactive to
     `overrides` (the user's pip choices).
- **`PowerDistribution.vue`** — the control: a segment/pip allocator per family
  (allocated vs available, +/- controls, SCM/NAV mode toggle). Emits per-family
  target segments → feeds `overrides`.
- **Wiring** — `useLoadoutStats` sustained DPS consumes the sim's weapon
  `poolRatio` (instead of the standalone `weaponPowerRatio`); Combat card +
  per-weapon rows react to the distribution; the signature card (later) too.

## Phases

Each phase lands as its own PR, validated against erkul on the **Asgard**.

### Phase 1 — Port construction + `useLoadoutSim` (default allocation)
- Parse the coverage-gap families (engine/lifeSupport power draw) or confirm
  absent; pin the non-weapon block sizing from the decode.
- Build `useLoadoutSim` (loadout → ports → `allocatePower` → result).
- **Validate the default allocation vs erkul** (per-family segments on the
  Asgard). No UI yet.

### Phase 2 — Wire default sustained (no regression)
- Replace the standalone `weaponPowerRatio` in `useLoadoutStats` with the sim's
  weapon `poolRatio`. Validate a sample of ships (ample-power ships unchanged;
  segment-starved ships now more accurate).

### Phase 3 — The pip UI
- `PowerDistribution.vue` control (per-family segments, +/- pips, SCM/NAV mode).
- User overrides flow into `useLoadoutSim` (erkul's `te`/`Q` override path);
  DPS/sustained recompute live. Optional: persist the user's setting.

### Phase 4 — Signatures (§6) react to the distribution
- Build the heat model (`coolingRatio`) + parse per-component EM/IR nominal.
- Emitted EM/IR (erkul's `dr`/`pr`) computed from the allocation → update as the
  user moves pips. Cross-section (`§6-CS`) is static (ship geometry × armor).

### Phase 5 — Follow-ons
- Overheat state (§3) from the heat model; flight boost (§8) via the IFCS sim.

## Validation

erkul parity on the **Asgard**: per-family default segments, sustained DPS at
default and at a couple of manual pip settings, and emitted EM/IR (Phase 4).
Each phase adds regression coverage in a spec.

## Risks / open questions

- **Non-weapon block sizing** — the exact segment sizing per non-weapon family
  isn't fully decoded; Phase 1 must pin it (decode `An`/`kn`/the family block
  construction) or reverse-fit against the Asgard.
- **Power ↔ heat coupling** — the default allocation's cooler pass (`ft`) needs
  the heat model; Phase 1 may use a simplified cooler allocation, refined in
  Phase 4.
- **UX** — how to present the power triangle (per-family bars vs erkul's pip
  segments); SCM vs NAV mode; whether pip settings persist per loadout.
- **Reactivity/perf** — recompute the sim on every pip change; keep it cheap
  (the allocation is O(segments), fine).
