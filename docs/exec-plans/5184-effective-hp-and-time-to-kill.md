# Effective HP and time-to-kill against a loadout

Working plan for #5184. Decisions live in the issue body. Deleted before the PR merges.

## Goal
For a target ship, show effective HP per damage type (shield, armor and hull combined, with shield absorption bleed-through) and the time-to-kill against a chosen attacker loadout's sustained DPS.

## Open questions
- None. Distortion, regen and the armor multiplier are now decided in the issue body.

## What changed

### Phase 1 — Defenses data
1. Add `hullHealth`, shield `maxRegen` and `damagedRegenDelay`, and armor `selfResistance<Type>`, to `GET /models/defenses` (`defenses.jbuilder`, `ModelDefenses`, schema components). Keep the query count flat (build preloaded).
2. Regenerate schema and clients.

### Phase 2 — EHP/TTK composable
1. `useTimeToKill.ts`: per damage type, damage the shield takes vs the share that bleeds through (`absorptionAtHealth`, `resistanceAtHealth` from `useDeflectionCheck.ts`), then armor, then hull. Integrate across shield health because absorption scales with it.
2. TTK = time to strip the layers at the attacker's sustained DPS per type (`computeLoadoutStats` from `useLoadoutStats.ts`), with shield regen handled as decided.
3. Distortion: EHP is shield-only and TTK is time to drop shields.
4. Vitest specs with hand-checked numbers (Gladius, Asgard as in `useDeflectionCheck.spec.ts`).

### Phase 3 — UI
1. Add EHP and TTK columns to `PenetrationCheckModal` rows (this ship's selected guns vs each target), sortable, honouring the shield/armor health sliders.
2. i18n keys in all 7 locales by hand.
3. Component spec.

## Intent Verification

- [x] **EHP per damage type** — a ship shows an EHP figure for each damage type, in which ballistic bleed-through during shields-up is accounted for.
- [x] **TTK vs a chosen loadout** — selecting an attacker loadout shows sustained DPS vs EHP as seconds to kill.

## Key files

| File | Role |
|------|------|
| `app/lib/model_defenses.rb` | Defenses rows per ship |
| `app/views/api/v1/models/defenses.jbuilder` | Defenses payload, lacks hull HP and regen |
| `app/api_components/v1/schemas/models/model_defense*.rb` | Defenses schema |
| `app/frontend/frontend/composables/useDeflectionCheck.ts` | Absorption/resistance at health, damage pipeline |
| `app/frontend/frontend/composables/usePenetrationCheck.ts` | Loadout weapon grouping, targets |
| `app/frontend/frontend/composables/useLoadoutStats.ts` | Sustained DPS per type |
| `app/frontend/frontend/composables/useShieldStats.ts` | Shield pooling across generators |
| `app/frontend/frontend/components/Models/PenetrationCheckModal/index.vue` | Existing attacker-loadout UI |
| `test/integration/api/v1/models_defenses_test.rb` | Endpoint test |

## Not in scope (deferred)
- **Per-face shield HP** — HP is a pooled total everywhere, so there is no face split.
- **Ammo-limited sustain** — `maxAmmo` does not cap sustained DPS today.
- **Missiles** — excluded from loadout DPS.

## Discovery Log

- **2026-10-01** Implementation. The simulation drains shield and armor in slices (50 and 25) so that absorption, resistance and deflection follow health; each slice is solved in closed form, so a target costs about 100 steps. DPS follows the combat card's convention (`damagePerShot × pellets × rate`), but the deflection check compares `damagePerShot / pellets` per pellet. The two conventions disagree for scatterguns. The pellet figure is kept as-is here so the margin and TTK columns agree with the existing check.
- **2026-10-01** Initial research. EHP/TTK existed in #4211 (`1dc1acc460`): `hull + shield/(1 - resist)` and a mirror-match TTK on burst DPS. #4289 (`820464f364`) removed it when Survivability was split into one-layer Defense and Hull cards.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
