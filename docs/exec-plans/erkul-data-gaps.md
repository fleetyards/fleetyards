# erkul data gaps — hardpoints / loadout stats

Date: 2026-08-06. Branch context: `feat/hardpoints-redesign`, flag `hardpoints-v2`.

Scope: **data / stat gaps only**. Loadout editing, ship-vs-ship compare, loadout
share/import, and component prices are explicitly **out of scope for now**
(editor + compare later; prices need a 3rd-party source).

Reference: live audit of erkul.games/calculator for the **Anvil Asgard**
(`anvl_asgard`, data v4.9.0-LIVE.12344265). Example values below are that ship.

## Legend

- **Source** = where the input data most likely lives in the SC game files
  (needs confirming while parsing). "have" = already parsed onto the component /
  model; "not parsed" = needs a parser + api_component + schema addition.
- Priority: **P1** correctness / high-value, **P2** valuable, **P3** nice-to-have.

---

## 1. Sustained DPS — SHIPPED shared-power-pool throttle (2026-08-07)

**DONE:** implemented erkul's `Io` sustained model scaled by a shared
weapon-power ratio (option A, max-power). Parser extracts weapon Power draw
(`power_consumption`) + ship `weapon_pool_size`; API exposes both;
`useLoadoutStats.sustainedRatio(weapon, powerRatio)` applies
`weaponPowerRatio = min(1, weaponPoolSize / ceil(Σ Power draw))`, provided from
the hardpoints page so per-weapon rows match the Combat card. Verified: Asgard
2 502 → **1 681** (matches the decoded formula on current 4.9.0 data; the older
1 835 was a stale snapshot), Gladius/unlimited ships unchanged at their
max-power duty cycle. Decoded formula + validation history below.



**CORRECTION (2026-08-06):** our per-weapon sustained is **validated exact vs
erkul** on normal ships (Aurora MR 0.5117 vs 0.5126; Guardian QI 0.6048 vs
0.6046 — memory `project_loadout_sustained_dps`). The Asgard discrepancy below
is a **high-demand edge case** (shared power/capacitor throttle), not a general
bug. Downgraded to P3. Details + narrowed scope in
`sustained-dps-power-sim.md` (Phase 0 outcome). Original notes retained below.


**Update (investigated 2026-08-06):** the calc already exists —
`useLoadoutStats.sustainedRatio()` models the energy-pool / overheat duty cycle
and the Combat card applies it. The earlier "sustained = burst (4 910)"
observation was **stale**: the DB lacked the weapon `regen` data at the time, so
`sustainedRatio` fell back to `1`. With the regen data now loaded, the card
already shows **Sustained 2 502** (not 4 910).

- **Have:** working duty-cycle calc + the regen data (`regen.maxAmmoLoad`,
  `maxRegenPerSecond`, `regenerationCooldown`, `costPerBullet`) and heat fields.
- **Remaining gap:** our number (2 502) ≠ erkul's (**1 835**) on the same data
  version (v4.9.0-LIVE.12344265). Per weapon: CF-337 ours ~51% of burst, erkul
  ~37% (burst 1 091 → sustained 408). Our model uses fire-full-pool → wait
  full-regen (`firingTime / (firingTime + cooldown + regenTime)`); erkul's
  effective factor is lower — likely a **continuous regen-limited** rate and/or a
  different reading of the regen field units (`maxAmmoLoad` 75 vs
  `requestedAmmoLoad` 18187, `costPerBullet` 48.5). Needs erkul-formula research
  to reconcile. **This is a model refinement, not a data gap.**
- **Spike notes (2026-08-06):** erkul shows no tooltip/definition for sustained
  or efficiency. Its sustained factor is a consistent **0.374** across weapons
  (CF-337 2×: burst 1 091 → sustained 408; 4×: 2 183 → 816) and does **not** fall
  out of our regen fields via any obvious formula. The `max*` vs `requested*`
  ammo-load/regen split (SC's power-throttle system) needs to be understood
  first. Recommend a scoped spike into SC weapon energy/power mechanics rather
  than guess-tweaking the ratio; `efficiency` (§2) is already correct and shipped.
- **FORMULA DECODED (2026-08-07) — from erkul's own JS** (`chunk-FWWRRMGF.js`,
  functions `Io`, `Mo`, `ue`, `z`, `Ot`, `U`). erkul's sustained is a per-weapon
  energy-pool cycle scaled by a **shared weapon-power ratio**:

  Per energy weapon (`Io(regen, alpha, fireRateHz, powerRatio)`, all tuning
  multipliers in `de` = 1):
  ```
  pool  i = round(maxAmmoLoad × powerRatio)
  regen s = maxRegenPerSec × powerRatio
  cycle c = regenerationCooldown + i/s + i/fireRateHz
  dpsSustain = i × alpha / c            (burst = alpha × fireRateHz)
  ```
  At `powerRatio = 1` this equals our current 51% duty cycle exactly (verified).

  The shared power ratio (`Mo`):
  ```
  consumption = ceil(Σ over weapons of z(weapon).units)   // z: resource.states[].flows[].consumes[Power].units
  poolSize    = vehicle.powerPools.pools[kind=Fixed, itemType=WeaponGun].poolSize
                (absent ⇒ "unlimited" ⇒ ratio 1 — why normal ships already match)
  weaponPowerRatio (max) = min(1, poolSize / consumption)
  poolRatio (default)    = min(1, selected / consumption)   // selected = default weapon power segments
  ```
  Displayed sustained uses `poolRatio`; the "efficiency %" erkul shows is
  `round(poolRatio × 100)`; the "max" (full weapon pips) uses `weaponPowerRatio`.

- **Data availability (confirmed in our raw files):** weapon Power draw is
  present (`resource="Power" Units="…"`, e.g. klwe_laserrepeater_s4 = 0.9); the
  Asgard vehicle XML has `itemType="WeaponGun" poolSize="4"`.
- **Open calibration:** the default `selected` (weapon power segments at the
  default power distribution) — needs one erkul ground-truth read to pin down
  (may equal `poolSize`, in which case default == max ratio).
- **Parser gap found:** our parser does **not** extract `regen` for the klwe
  laser repeaters (on-disk parsed JSON has no `regen` block though the raw XML
  has `WeaponRegenConsumerParams`). Must be fixed for the model to work off
  parsed data.
- **Implementation scope:** parse per-weapon Power `units` + fix weapon regen
  extraction; parse vehicle `weaponPoolSize`; expose both via api_components;
  rewrite `useLoadoutStats` sustained to the `Io`/`Mo` model above.

## 2. Weapon "efficiency %" — SOLVED, needs display only (P2, display)

**Update (investigated 2026-08-06):** erkul's per-weapon **`51% efficiency`**
**is exactly our `sustainedRatio`**: `firingTime / (firingTime + cooldown +
regenTime)` = `6 / (6 + 0.74 + 5) = 0.511` for the CF-337 — matches erkul's 51%.
We already compute this internally in `useLoadoutStats`.

- **Have:** the value (as `sustainedRatio`), just not surfaced.
- **Gap:** display it. Expose it on `WeaponStat` (e.g. `efficiency`) and show it
  per-weapon (hardpoint weapon rows and/or the Combat card weapon breakdown),
  the way erkul does next to sustained DPS.
- **Note:** erkul labels this 51% even though its *sustained* is ~37% of burst —
  i.e. erkul's efficiency % and its sustained factor are two different numbers
  (see §1). Ours currently uses the one ratio for both; reconcile alongside §1.

## 3. Weapon overheat / heat capacity (P2, mostly have)

erkul shows an overheat state per weapon ("NO OVERHEAT") derived from heat per
shot vs the weapon/ship cooling capacity.

- **Have:** `heatPerShot` / `heatPerSecond` on weapons; cooler `coolingRate`.
- **Gap:** the overheat threshold / cooldown params per weapon, and the model
  that combines weapon heat with ship cooling.

## 4. Gimbal / turret turn rate (P2, likely not parsed)

erkul shows mount turn rate in °/s (Asgard: PC2 Dual mount 35 °/s, VariPuck
gimbal 80 °/s).

- **Source:** mount / joint params in the item or vehicle XML.
- **Have:** not parsed.

## 5. Armor stats (P2, not parsed)

erkul Defense card: **Armor HP 23 760**, **deflection** (Phys 139 / Energy 88),
**damage reduction** (Phys 30% / Energy 50%), **self-resistance** (Phys 19% /
Energy -15%).

- **Source:** ship armor component (`SCItemVehicleArmorParams` or similar) in the
  entity / implementation XML.
- **Have:** we parse armor damage resistances for the ARMOR hardpoint category
  (physical/energy/distortion/thermal %) but not the ship-level armor HP,
  deflection, damage reduction, or self-resistance summary.

## 6. Emitted signatures + modifiers (P2, mostly blocked on the power/heat sim)

erkul: emitted **IR 8.4k / EM 31.2k / CS 30.4k** plus armor signature modifiers
(EM/IR/CS +9%).

**Spike (2026-08-07) — decoded from erkul's JS** (`chunk-FWWRRMGF.js`: `Ao`,
`Ro`, `dr`, `pr`). erkul's `signature = {em, ir, crossSection:{x,y,z},
armorModifier, sources[]}`:

- **CS** = `vehicle.crossSection.{x,y,z} × armor.signalCrossSection`, and the UI
  shows the **max axis**. Source data is static:
  `crossSectionParams → SSCSignatureSystemManualCrossSectionParams → crossSection`
  (Asgard 20139/7624/27912; max 27912 × ~1.09 armor ≈ erkul's 30.4k). **Clean +
  implementable.**
- **EM** (`dr`) = Σ each component's `emNominal` (its resource `Online`-state
  `signature.em.nominal`) **scaled by the live power allocation** — only
  `poweredOn` components, weighted by `activeSegments`, power-range modifiers,
  then × armor EM multiplier.
- **IR** (`pr`) = Σ `irNominal × (activeSegments/units) × power-range modifier ×
  ship coolingRatio × armor IR multiplier`.

**Verdict:** EM/IR are live functions of the **power-allocation + heat
simulation** we don't have (same blocker as §1 sustained DPS). Faithful EM/IR
needs that subsystem — not a gap-fill. **Only CS is cleanly deliverable.**

- **Have:** radar *detection* signatures (RADAR); armor signal multipliers
  (parsed on the armor component).

## 7. Countermeasures counts (P3, may partly have)

erkul: **Decoy 192, Noise 20**.

- **Have:** countermeasure hardpoints + their ammo (`maxAmmo`) are parsed; need
  to confirm we can total decoy vs noise ammo per ship.

## 8. Flight: boost + engine state (P2, likely not parsed)

erkul Flight card: SCM **203 → 425 boosted (240 back)**, **full boost regen
44.5 s**, **boost delay 0.9 s**, engine power state (2/6 SCM).

- **Source:** IFCS / flight-controller params in the vehicle XML.
- **Have:** base SCM speed + pitch/yaw/roll on the model metrics; boosted values,
  boost regen/delay, and engine power state are not parsed.

## 9. Quantum range — SOLVED (2026-08-06)

erkul + spviewer: Asgard **115.6 Gm** on 1.85 SCU. Reproduced exactly.

- **Formula:** `range_Gm = quantumFuelTankSize_SCU × 1000 / quantumFuelConsumption`,
  where `quantumFuelConsumption` is the QD's **milli-SCU-per-Gm** figure from
  `ItemResourceComponentParams → states[Travelling] → deltas →
  consumption[resource=QuantumFuel] → resourceAmountPerSecond →
  SMicroResourceUnit.microResourceUnits`. NOT `quantumFuelRequirement` (that gave
  −46%…+145% errors) and NOT size-tiered (S3 Kama=26 vs Erebos=18).
- **Validated** vs erkul AND spviewer across 8 drives / S1–S4 (S1=10, S2=16,
  S3 Kama=26 / Erebos=18, S4=75 milli-SCU/Gm).
- **Shipped:** parser extracts `quantum_fuel_consumption`;
  `ComponentQuantumDrive` schema exposes `quantumFuelConsumption`;
  `useHardpointStats` shows a "Range … Gm" stat on the quantum-drive row (tank
  size provided by the hardpoints page).

## 10. Missile / bomb / EMP damage totals — DONE (missiles)

erkul: **51 200 missile dmg**, plus bomb / EMP totals.

- **Shipped (2026-08-06):** `useLoadoutStats` now sums missile `damagePerShot`
  into `missileDamage`, surfaced as a "Missile Damage" line on the Combat card.
  Matches erkul (Asgard = 51 200). Bomb/EMP totals deferred until a carrier ship
  is available to validate.

## 11. DPS by control group (P3, grouping)

erkul splits DPS into **Pilot / Manned turret / Remote turret / PDS**. We split by
damage type (composition) and per-weapon, but not by who controls the weapon.

- **Source:** the hardpoint's control type is in the mount data (pilot vs
  turret); needs a group axis on the loadout-stats aggregation.

## 12. Hull part classification — DONE

erkul: **Vital 2 (40 000 hp) / Secondary 9 (26 600 hp) / Breakable 6 (5 400 hp)
/ Subpart 2 (5 000 hp)**, 27 parts total.

- **Shipped:** the parser classifies each part (`part_category`) and the model
  exposes `hullParts[{name, health, category}]` with the vital / secondary /
  breakable / subpart enum. The Survivability card renders the breakdown by
  class (behind the "Show parts" toggle). Not a gap.

---

## Suggested order

1. **§1 + §2** together — sustained-DPS throttle and the efficiency % (same
   underlying energy/heat model; the biggest correctness win, and our card is
   actively wrong today).
2. **§5 + §6** — armor + emitted signatures (a real Defense-card gap; new parsing
   but self-contained).
3. **§8 + §9** — flight boost + quantum range (rounds out the flight/travel data).
4. **§10 + §12** — missile aggregate + hull part class.
5. **§3, §4, §7, §11** — smaller polish.

## Deferred (not data gaps — tracked in loadout-dps-calculator.md)

Interactive per-slot loadout editor + persistence; ship-vs-ship / loadout-vs-
loadout compare; loadout share/import (erkul codes); component prices / build
cost (needs a 3rd-party price source).
