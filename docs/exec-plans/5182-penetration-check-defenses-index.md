# Penetration check: which ships can my weapons pierce

Working plan for #5182. Decisions live in the issue body. Deleted before the PR merges.

## Goal
From a ship's loadout, open a penetration check that lists every ship in the current build and whether the loadout's guns punch through its shields and armor deflection.

## What changed

### Phase 1 — Defenses index
1. `GET /models/defenses`: one slim row per visible, active model with armor (health, damage multipliers, deflection) and shields (max health, absorption, resistance) from the build in force.
2. Components `ModelDefense`, `ModelDefenseArmor`, `ModelDefenseShield`, `ModelDefensesList`.
3. Integration test, schema regenerated.

### Phase 2 — Penetration check
1. Split `computeArmorStats` / `computeShieldStats` so they also build from raw armor/shield data, not only from hardpoints.
2. Extract the per-weapon evaluation out of `computeDeflectionCheck`; add `computePenetrationCheck` running it per target ship.
3. `PenetrationCheckModal` opened from the Combat card: weapon picker, target health sliders, ship-size filter, tally, threshold-split list.
4. Translations in all seven locales.

## Intent Verification

- [ ] `/models/defenses` returns armor + shield data for every ship with either, from the current build
- [ ] Modal lists ships sorted by margin with a divider at the threshold, `n deflected · n pierce` tally, size filter and both health sliders

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/models_controller.rb` | `defenses` action |
| `app/views/api/v1/models/defenses.jbuilder` | slim rows |
| `app/frontend/frontend/composables/useDeflectionCheck.ts` | shared pipeline |
| `app/frontend/frontend/components/Models/PenetrationCheckModal/index.vue` | modal |

## Discovery Log

- **2026-09-30** Armor and shield slots sit on the model in all but 3 cases (shields nested one level under another slot); the index resolves both.

## Progress
- [ ] Phase 1
- [ ] Phase 2
