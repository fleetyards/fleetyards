# Loadout Stat Formulas

**Date:** 2026-09-24 (worked out 2026-08-06 to 2026-08-11)

These are the formulas behind a vehicle's loadout stats: sustained DPS, weapon power, the power-segment allocation, cooling, the EM/IR/CS signatures and quantum range. They were verified against the Anvil Asgard (`anvl_asgard`, data `4.9.0-live.12344265`).

**Status of the port.** The allocation primitives, the SCM/NAV base and fill passes, cooling/`coolingRatio`, EM and IR live in `app/frontend/frontend/composables/powerSim.ts` and `useLoadoutSim.ts`. Sustained DPS and quantum range are in `useLoadoutStats`/`useHardpointStats`. **Not ported:** the cooler heat-balancing pass and the refinement passes. The port therefore does not balance coolers against heat in its default distribution.

## Sustained DPS

Per energy weapon, from `(regen, alpha, fireRateHz, powerRatio)`. No tuning multipliers apply.

```
pool  i = round(maxAmmoLoad × powerRatio)
regen s = maxRegenPerSec × powerRatio
cycle c = regenerationCooldown + i/s + i/fireRateHz
dpsSustain = i × alpha / c            (burst = alpha × fireRateHz)
```

At `powerRatio = 1` this is the plain duty cycle `firingTime / (firingTime + cooldown + regenTime)`, which is also the per-weapon efficiency % shown next to sustained DPS (CF-337: `6 / (6 + 0.74 + 5) = 0.511`). The duty cycle was validated exact on ordinary ships: Aurora MR 2× CF-117 gave 0.5117 against 0.5126, and Guardian QI 2× M7A gave 0.6048 against 0.6046.

The ship-wide weapon power ratio:

```
consumption = ceil(Σ over weapons of resource.states[Online].flows.consumes[Power].units)
poolSize    = vehicle.powerPools.pools[kind=Fixed, itemType=WeaponGun].poolSize
              (absent ⇒ unlimited ⇒ ratio 1)
weaponPowerRatio (max)  = min(1, poolSize / consumption)
poolRatio (default)     = min(1, selected / consumption)   // selected = allocated weapon segments
```

Displayed sustained uses `poolRatio`, and the efficiency % is `round(poolRatio × 100)`. The "max" figure (full weapon pips) uses `weaponPowerRatio`. The fill pass puts weapons at `min(weaponConsumptionPoints, poolSize)` segments, so on a ship with enough power the default `poolRatio` equals `weaponPowerRatio`. The full allocation only changes the answer for ships that run short of power segments, and when a user moves pips off weapons.

Asgard: burst 4,910. The plain duty cycle gives 2,502, and the pool ratio brings sustained to **1,681** on 4.9.0 data. An older figure of 1,835 was stale. The Asgard's 4 weapon-pool segments (`itemType="WeaponGun" poolSize="4"`) against its weapon draw are what throttle it. Ships without a weapon pool already match at ratio 1.

**The regen fields.** `requestedAmmoLoad / cost` and `requestedRegenPerSec / cost` are constant within a weapon family (CF-337 and CF-447 both give 375 shots and 62.5 shots/s). So `requested_*` is the real energy pool and regen, and `max_*` (75/15) is a smaller local capacitor. The formula uses `max*`. No combination of these fields reproduces the throttled figure, so the throttle is not hidden in them; it is the pool ratio. Sample inputs:

| weapon                           | burst | duty cycle | maxAmmoLoad / maxRegen/s / cost | requestedAmmoLoad / requestedRegen/s |
| -------------------------------- | ----- | ---------- | ------------------------------- | ------------------------------------ |
| CF-337 (`klwe_laserrepeater_s3`) | 546   | 0.511      | 75 / 15 / 48.5                  | 18187 / 3031                         |
| CF-447 (`klwe_laserrepeater_s4`) | 818   | 0.507      | 75 / 15 / 72.7                  | 27262 / 4544                         |
| `amrs_lasercannon_s3`            | 547   | 0.531      | 25 / 3 / 202                    | 20200 / 3375                         |
| `amrs_scattergun_s3`             | 462   | 0.923      | 75 / 15 / 440                   | 15400 / 2567                         |

## Power allocation

A power plant produces `resource.states[Online].flows[generate].produces[Power, unitKind=powerSegment].units` segments, summed over the powered-on plants. **The default distribution is an algorithm, not a data field.** A vehicle's `initialPowerAllocation` short-circuits it when present, but the Asgard has none. The allocator is a multi-pass greedy over the family buckets `{weapon, engine, shield, qdrive, radar, lifeSupport, coolers, qed, emp, miningLaser, salvage, tractorBeam, towingbeam}`, run once for SCM and once for NAV:

1. The base pass: a minimum per family, in priority order. In SCM that is lifeSupport → miningLaser → salvage → emp → weapon(1) → shield → radar → engine …. NAV swaps qdrive in for weapon, shield and emp.
2. The fill pass: weapons go up to `min(weaponConsumptionPoints, poolSize)`, then shield / radar / engine.
3. The cooler heat-balancing pass: a loop of at most 200 iterations that adds cooler segments until cooling ≥ heat generation.
4. The refinement passes: cooler refinement and distribution of what remains.

Each port is built from item and loadout data into its `size`/`family`/`critical`/`floor`/`units`.

**Primitives.** State is `{remaining, perPort:{}, perFamily:{…0}}`. A port is `{portPath, family, size, disabled, critical, selected, poweredOn, floor, units}`, where `size` is the number of segments it occupies.

- Allocate (atomic): `selected=true; perPort[port]+=size; perFamily[family]+=size; remaining-=size`, with a matching undo.
- Critical base: allocates each port that is `!disabled && critical && !selected && size<=remaining`.
- Greedy fill: allocates each `!disabled && !selected` port until one does not fit, then stops.
- Weapons base: allocates weapons up to a segment cap; the base pass uses 1.
- Family fill: fills a family up to `target - perFamily[family]` more segments.
- Port fill: fills one specific port up to n segments.
- Cooler segment search, **heat-coupled**: scans a cooler's segments from `floor..units` and returns the first where `cooling(seg) ≥ coolingConsumptionPerSec`. This is the power↔heat link the heat-balancing pass iterates.

**Power and heat are coupled.** The heat-balancing pass sets cooler segments against heat generation, so the power allocation depends on the heat model. They cannot be built as independent passes: either the heat pass is built together with the allocation, or the allocation assumes a simplified cooler rule and the heat pass refines it later. Flight/IFCS is the only truly independent piece.

**Coverage gap.** The allocation assigns power to `engine` and `lifeSupport`. A faithful full allocation needs their Power draw, plus the exact block sizes for non-weapon families.

## Heat and cooling

**Power-range modifier `powerModifier(powerRanges, seg)`.** `powerRanges` is a list of `{start, modifier}` sorted by `start`. It returns the `.modifier` of the entry where `start ≤ seg < nextStart` (the last entry runs to ∞), and defaults to 1. The parsed `power_ranges {low, medium, high}` holds the same three entries and has to be reshaped into a start-sorted list.

Only coolers take part (`item.category === "Cooler"`). For each cooler, `units` is its power draw and `ratedCooling` is `produces[Coolant].units` (`cooling_rate`):

```
floor     = round(units × (minimumFraction || 1/units))
activeSeg = poweredOn && seg ≥ floor && floor > 0 ? clamp(seg, 0, units) : 0
effectiveCoolingPerSec = ratedCooling × (activeSeg/units) × powerModifier(powerRanges, activeSeg)
coolingPerSec    = Σ effective
coolingMaxPerSec = Σ ratedCooling × powerModifier(powerRanges, units)
heat u = Σ active segments across all families (weapons count min(selected, consumption))
       + Σ over shield/lifeSupport/radar/qdrive of activeSeg × powerModifier(powerRanges, activeSeg)
coolingRatio = coolingPerSec > 0 ? min(u / coolingPerSec, 1) : (u > 0 ? 1 : 0)
```

`useLoadoutSim.computeHeat` intentionally departs from this. It leaves the ratio uncapped, so it reads above 1 when the ship is under-cooled, and returns 0 when no cooler is powered. Whether the COOLING bar displays `coolingRatio × 100` or `coolingPerSec / coolingMaxPerSec` is unconfirmed. An idle Ironclad at 90% is a usable check.

## Signatures

`signature = {em, ir, crossSection:{x,y,z}, armorModifier, sources[]}`. Each port's nominals come from the item's `resource.states[Online].signature.{em,ir}.nominal`. The armor multipliers `signalElectromagnetic`/`signalInfrared`/`signalCrossSection` live on the armor item and default to 1.

- **CS** = `vehicle.crossSection.{x,y,z} × armor.signalCrossSection`, and the displayed value is the largest axis. The source is `crossSectionParams → SSCSignatureSystemManualCrossSectionParams → crossSection`. For the Asgard that is 20139/7624/27912, and the max axis 27912 × ~1.09 armor gives ≈ 30.4k. CS does not depend on power.
- **EM** = `armor.signalElectromagnetic × Σ` of four kinds of term:
  - shields: `emNominal × powerModifier(pr, f) × shieldRatio`, with `f = round(totalSeg × shieldRatio) / nShields`;
  - weapons: `emNominal × powerModifier(pr, weaponSelected) × selected/enabled`;
  - the segment-scaled sources (shields, coolers, radar): `emNominal × powerModifier(pr, activeSeg) × activeSeg/units`;
  - every other powered port: `emNominal × powerModifier(pr, seg) × seg/powerSegmentUnits`.
- **IR** = `coolingRatio × armor.signalInfrared × Σ over heat.sources of irNominal × (activeSeg/units) × powerModifier(powerRanges, activeSeg)`. It is gated by `coolingRatio` and is 0 when there is no power.

`pr` is the port's `powerRanges`. Asgard reference values: IR 8.4k, EM 31.2k, CS 30.4k, with armor modifiers of +9% on each.

## Quantum range

Asgard: **115.6 Gm** on 1.85 SCU.

```
range_Gm = quantumFuelTankSize_SCU × 1000 / quantumFuelConsumption
```

`quantumFuelConsumption` is the drive's fuel use in milli-SCU per Gm, read from `ItemResourceComponentParams → states[Travelling] → deltas → consumption[resource=QuantumFuel] → resourceAmountPerSecond → SMicroResourceUnit.microResourceUnits`. It was validated across 8 drives from S1 to S4: S1 = 10, S2 = 16, S3 Kama = 26 / Erebos = 18, S4 = 75.

Rejected approaches, with the reasons:

- `quantumFuelRequirement` gives errors from −46% to +145%.
- Size tiers do not work. Two S3 drives differ by 26 against 18, so a figure per size cannot be right.

## Other Asgard reference values

- **Missile damage:** 51,200. `useLoadoutStats` reproduces it by summing `damagePerShot`.
- **Hull parts:** Vital 2 (40,000 hp), Secondary 9 (26,600), Breakable 6 (5,400), Subpart 2 (5,000), 27 in total.
- **Flight:** SCM 203 → 425 boosted (240 back), full boost regen 44.5s, boost delay 0.9s. The IFCS inputs are the afterburner `capacitorMax`, `capacitorRegenPerSec`, the NAV/SCM `regenCurvePoints`, `regenDelayAfterUse` and the boost multipliers, read from the flight-controller slot. None of this is worked out yet.
- **Countermeasures:** Decoy 192, Noise 20.
- **Mount turn rate:** PC2 Dual mount 35°/s, VariPuck gimbal 80°/s.
