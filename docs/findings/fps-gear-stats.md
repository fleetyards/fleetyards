# FPS Gear Stats: What the Game Files Carry and How the Figures Are Derived

**Date:** 2026-11-03 (measured against 4.10.2-live; tracked in #6149)

`ScData::Parser::GearStats` reads what personal gear does from its record and the records it points at. This note records the record shapes behind it and the traps in deriving figures from them. Read it before changing the gear stats parser or the per-mode maths on the frontend.

## Where the figures live

| What                       | Where                                                                                                                                         |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Fire modes                 | `SCItemWeaponComponentParams.fireActions`: Rapid, Single, Burst, Charged, Beam, wrapped in Sequence, Parallel and DynamicCondition            |
| Second-button tool actions | `SCItemWeaponComponentParams.aimAction > SWeaponActionConditionParams` — the multi-tool's Repair and main TractorBeam live here, one per head |
| Magazine                   | the record `ammoContainerRecord` names (its `SAmmoContainerComponentParams`), or the weapon's own container                                   |
| Round                      | `ammoparams/**`, by the container's `ammoParamsRecord`; a second round by `secondaryAmmoParamsRecord`                                         |
| Heat                       | `connectionParams.simplifiedHeatParams`                                                                                                       |
| Blade attacks              | the `MeleeCombatConfig` record `meleeCombatConfig` names, under `weapons/melee/`                                                              |
| Grenade                    | `EntityComponentTriggerableDevicesParams.triggers` (fuse = timer `duration`); `aiTriggers` is the AI's weaker copy                            |
| Mine                       | `SSensorMineComponentParams.TriggerType`, blast in `SHealthComponentParams.DeathExplosionParams`                                              |
| Mining gadget              | `EntityComponentAttachableModifierParams.modifiers.ItemMineableRockModifierParams` — not the laser-module block; adds a cluster factor        |
| Consumables                | `consumabletypesdatabase/consumabletypes.records.xml`, effects per microSCU, scaled by the dose's volume                                      |

## Traps

- **Charged modes.** `maxChargeModifier.damageMultiplier` is a plain factor: the Scourge's 20-damage round × 300. A non-zero `pellets` there replaces the pellet count at full charge (a pistol going to 7 pellets at ×0.25). The cycle is charge time plus the longer of the cooldown and the wrapped action's shot time.
- **Sequences.** An entry's `delay` with `unit=RPM` is the sequence's cadence, but a step lasts as long as the burst it fires when that is longer: the Pulse's 625 rpm sequence wraps a three-round burst that takes 0.4 s.
- **Two rounds per magazine.** A mode's `SProjectileLauncher.projectileType` says which one it fires; the Arlington's slug and buckshot share one magazine.
- **Launcher rounds.** Most of a grenade-launcher or rocket round's damage is its `detonationParams` blast; pellets and a charge scale the impact only.
- **Cooling.** `timeTillCoolingStarts` is a delay after the last shot, so cooling only runs where a mode pauses that long. A burst with a 0.25 s cooldown against a 1 s delay never cools while it fires.
- **Placeholder rounds.** Medgun refills, multi-tool canisters and tool batteries name a round that real energy guns also fire, so the round cannot tell them apart. Only a container some gun names as its magazine keeps one.
- **Penetration.** `maxPenetrationThickness` is 5,000 on most rifles, which reads as "no limit". It is parsed but not shown.
- **Recoil.** Procedural curves in separate records with no single figure; attachments' recoil multipliers are read, weapons' recoil is not.
- **Creature weapons.** `vlk_*` records are the valakkar's attacks, built as guns and named after the BR-2 Shotgun.
- **Duplicate labels.** The HUD labels collide (`[SEMI]` twice on the Arlington, two "Tractor" actions on the multi-tool); the page adds the mode's own name.
