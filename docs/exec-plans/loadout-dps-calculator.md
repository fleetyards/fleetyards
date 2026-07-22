# Loadout DPS Calculator

Goal: build toward an in-app DPS / loadout calculator comparable to erkul.games and
spviewer.eu, which today are only linked to externally from the hardpoints view.

## Context / current state

The raw combat data is already imported from extracted game files and exposed on the
API:

- `useModelHardpoints(slug, { source })` returns a flat `Hardpoint[]`, each with
  `category`, `group`, `component.typeData`, and nested `hardpoints[]` (turret guns).
- `ComponentWeapon.typeData`: `damagePerShot` / `damagePerSecond` (per damage type:
  physical/energy/distortion/thermal/biochemical/stun), `fireRate` (rounds **per
  minute** — S9 cannon = 60), `pelletsPerShot`, `speed`, `range`, `beam`.
- Per-component stats already render in `Models/Hardpoints/Details/index.vue`.
- `number.json` already defines a `dps` format (`"%{count} DPS"`).

What's missing (see the full gap analysis): a calculation/aggregation layer, aggregate
UI, a real per-hardpoint picker + persistence, and ship hull HP for EHP/TTK.

## This slice: read-only aggregate DPS panel (frontend-only)

No backend, no migration, no new API. Aggregate the **default-equipped** components
already returned by `useModelHardpoints` and display headline combat numbers on the
ship page, reflecting the existing game-files / ship-matrix source toggle.

### Steps

1. **`composables/useLoadoutStats.ts`** — pure rollup over `Hardpoint[]`.
   - Recursively collect weapon hardpoints (`category === WEAPONS`) with a component.
   - Classify each `ComponentWeapon`:
     - beam (`beam && damagePerSecond`) → contributes to sustained DPS only.
     - projectile (`fireRate && damagePerShot`, not beam) → alpha = `Σ perShot ×
       pellets`; DPS = `alpha × fireRate / 60`.
     - missile (has `trackingSignal`, no `fireRate`) → excluded in v1 (one-shot; note
       as follow-up).
   - Output `dps` and `alpha` as `{ total, physical, energy, distortion, thermal }`,
     plus `weaponCount` and `hasData`.
2. **`useLoadoutStats.spec.ts`** — vitest unit test with synthetic hardpoints
   (projectile + beam + nested turret gun) asserting the arithmetic.
3. **`components/Models/CombatMetrics/index.vue`** — mirrors `BaseMetrics` styling;
   renders total DPS, alpha, and per-damage-type split. Renders only when
   `weaponCount > 0`.
4. **Mount** in `Models/Hardpoints/new.vue` (owns hardpoints + source toggle) so it
   tracks the selected source.
5. **i18n** — add `labels.metrics.combat` and a `labels.combat.*` block (en).

### Explicitly deferred

- Missiles, gimbal/convergence, spread/recoil.
- Sustained-vs-burst power/heat budget simulation.
- EHP / TTK (needs ship hull HP import — absent on `Model`).
- Interactive per-hardpoint picker + persistence to `VehicleLoadoutHardpoint`.
- Loadout-vs-loadout comparison.
