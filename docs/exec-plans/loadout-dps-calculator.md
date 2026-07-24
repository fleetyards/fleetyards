# Loadout DPS Calculator

Goal: build toward an in-app DPS / loadout calculator comparable to erkul.games and
spviewer.eu, which today are only linked to externally from the hardpoints view.

Branch: `feat/loadout-dps-readonly`.

## Data foundation (already imported from extracted game files)

- `useModelHardpoints(slug, { source })` returns a flat `Hardpoint[]`, each with
  `category`, `group`, `component.typeData`, and nested `hardpoints[]` (turret guns).
- `ComponentWeapon.typeData`: `damagePerShot` / `damagePerSecond` (per damage type:
  physical/energy/distortion/thermal/biochemical/stun), `fireRate` (rounds **per
  minute**), `pelletsPerShot`, `speed`, `range`, `beam`.
- `ComponentShield.typeData`: `maxHealth`, `maxRegen`, per-type `resistance.{type}.max`.
- Hull HP: **not** in the Foundry Records entity (`SHealthComponentParams.Health` is a
  placeholder). It lives in the CryEngine vehicle implementation XML at
  `Data/Scripts/Entities/Vehicles/Implementations/Xml/<ship>.xml`, referenced by the
  entity's `VehicleComponentParams.vehicleDefinition`, as `<Part damageMax>` per part.
  `vehicleHullDamageNormalizationValue` is a damage-normalization constant, **not** hull
  HP (600i: 55k vs real 197k) — do not use it.

## Done

### Read-only aggregate DPS panel (frontend-only)
- `composables/useLoadoutStats.ts` (+ spec) — rolls up default-loadout weapons into
  `dps` and `alpha` per damage type, plus a per-weapon list. Recurses into turrets;
  excludes missiles.
- `components/Models/CombatMetrics/index.vue` — hero tiles (total DPS, alpha, weapon
  count), damage-composition bar with hover-isolate, animated collapsible per-weapon
  table (`Collapsed`).
- Note: our DPS = alpha × fireRate/60 = erkul **burst** DPS (theoretical max fire
  rate), labelled "burst". We do **not** model heat/power throttling, so we don't
  produce erkul's lower "sustained" number.

### Survivability card (frontend + backend)
- `composables/useShieldStats.ts` (+ spec) — total shield HP, regen, HP-weighted
  per-type resistances from default-loadout shields.
- `components/Models/SurvivabilityMetrics/index.vue` — shield HP + hull HP tiles,
  resistance bars.
- Shared frame extracted to `components/Models/metricsCard.scss`.

### Hull HP end-to-end pipeline
- Parser `ScData::Parser::ModelsParser#extract_hull_health` sums `<Part damageMax>`
  from the implementation XML → `hull_health` on parsed model JSON (regenerated).
- Migration `add hull_health` + `ModelsLoader` maps it.
- API: `hullHealth` on the model metrics schema + jbuilder (omitted when absent).
- Validated vs erkul within patch tolerance (600i 198,500 vs 197,250; 211/245 models
  populated — the rest have no implementation XML).

### Layout
- Combat + survivability cards sit in a two-column row at the top of the hardpoints
  section (`Models/Hardpoints/new.vue`).

## Still missing / next slices

1. **Per-part hull exposure** — we only expose the total. erkul shows each part
   (name, HP) and a vital / secondary / breakable / subpart classification. Parts and
   `damageMax` are available in the implementation XML; the class split needs more
   digging into the part damage-behavior data. Would need a `hull_parts` store
   (jsonb column or table), API array, and a breakdown UI.
2. **EHP / time-to-kill** — combine shield HP (× resistances) + hull HP into an
   effective-HP / TTK-vs-a-loadout figure. Now unblocked by hull HP.
3. **Sustained DPS** — model power draw vs power-plant output and heat vs cooler
   capacity to derive erkul's throttled sustained DPS (currently burst only).
4. **Interactive per-hardpoint picker + persistence** — swap components per slot and
   recompute; persist to the existing `VehicleLoadoutHardpoint` table (schema ready).
5. **Loadout-vs-loadout / ship-vs-ship combat comparison** — extend `compare.vue`.
6. **Weapon detail gaps** — spread/recoil and projectile falloff aren't imported, so
   effective-DPS-at-range can't be computed yet. Missiles and gimbal/convergence
   deferred.
7. **i18n** — only `en` has the new `labels.combat.*` / `labels.survivability.*` keys
   and the `dps` number format; other locales fall back to English.

## Verification / ops notes

- Tests: `pnpm vitest run app/frontend/frontend/composables/*.spec.ts` (loadout +
  shield stats).
- Regenerating hull HP after a game-data version bump: rerun `ModelsParser#all` (writes
  `data/sc_data/parsed/.../models`), then `ScData::Loader::ModelsLoader#all`.
- After schema changes: `./bin/generate-schema` (regenerates swagger + orval client),
  then format + lint.
