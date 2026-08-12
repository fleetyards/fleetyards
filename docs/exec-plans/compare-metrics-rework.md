# Compare page rework — metrics-card language + the new ship metrics

Branch: `feat/compare-metrics-rework` · worktree: `.worktrees/feat/compare-metrics-rework`

## Why

The ship detail page moved to the `MetricsCard` idiom (hero tiles, composition bars, chip
rows) and gained whole metric families that did not exist when the compare page was built:
burst/sustained DPS, damage composition, shield HP/regen/resistances/absorptions, armor
HP/deflection/reduction, hull HP/parts/doors, weapon power pool, signature cross-section.

The compare page still renders the pre-redesign matrix (`compare-row` + `metrics-label` /
`metrics-value`) and only covers Base / Crew / Speed / Cargo / Hardpoints. Everything a
player actually compares ships _for_ today — how hard they hit, how much they soak — is
missing, and the page reads like a different product than the ship page.

## Approved direction (2026-08-12)

- **Layout: matrix rows in metrics-card language.** Ships stay columns, metrics stay rows —
  a matrix is what a compare page is _for_; scanning one number across ships beats
  re-reading N cards. Each section gets a `MetricsCard` frame, HUD-styled rows, and
  per-row winner markers. (Rejected: one card column per ship — loses row alignment;
  per-section card rows — numbers only roughly align.)
- **New sections: Combat, Defense, Hull, Fuel & quantum.** Cargo gets reworked into the
  same language rather than left alone.
- **Highlight best _and_ worst** per row, only where the metric has an unambiguous
  direction.

## Design

### Grid, not flex rows

Today each row is its own flex row with `min-width: 450px` items, so columns only line up
by coincidence of identical rules and 8 ships means a very wide scroll.

New: one CSS grid template shared by every section, driven by custom properties on the
stack that wraps all the section cards:

```
--compare-label: 170px
--compare-col: 420px
--compare-cols: var(--compare-label) repeat(<n>, var(--compare-col)) 1fr
min-width: calc(var(--compare-label) + <n> * var(--compare-col))
```

Three things here were wrong on the first attempt and are worth keeping written down:

- **Fixed tracks, not `1fr`.** A flexible track sizes against its content, and the store
  images' intrinsic width stretched a two-ship comparison to ~1000px per column. The
  trailing `1fr` soaks up leftover width instead. `minmax(0, 1fr)` also avoids the blowup
  but then eight ships squeeze below the legible minimum.
- **420px per column**, not 210px. That is the width the hardpoint group cards were
  designed against on the ship page (`col-lg-4` of the fluid container); narrower and
  component names wrap one letter per line. Eight ships ⇒ ~3.5k px, still under today's
  ~3.9k.
- **The horizontal scroll stays at document level**, no `overflow-x: auto` container: such
  a container is a scrollport on both axes, which would break the ship-name row's
  `position: sticky; top: 0`.

The label cell is `position: sticky` at `--compare-sticky-left`, which is the **navigation
rail's width** (300px, 80px slim) — the page scrolls underneath the fixed nav, so sticking
at 0 parks the labels behind it. This is what the old code's `left: 220px` plus all that
`slim` prop plumbing was reaching for; it never worked because the cell was never
positioned. The rail also needs an opaque background plus a `::before` slab covering the
strip left of it: the nav is translucent, so the columns are otherwise visible sliding
along behind it as torn-off text.

### Components

| Path                                  | Role                                                                                                                    |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `Compare/Models/Section/index.vue`    | Section frame: `MetricsCard` + collapse toggle in the (currently unused) `#head` slot, `Collapsed` body, `hasData` gate |
| `Compare/Models/StatRow/index.vue`    | One metric row: sticky label cell + one value cell per model, best/worst classes, `#cell` slot escape hatch             |
| `Compare/Models/ChipsRow/index.vue`   | Multi-valued row (resistances, absorptions, deflection, reduction) reusing DefenseMetrics' chip look                    |
| `Compare/Models/ContentRow/index.vue` | Per-model slot row for composition bars, silhouettes and hardpoint group lists                                          |
| `Compare/Models/Header/index.vue`     | Store image + remove button per ship, plus the sticky ship-name row                                                     |
| `Compare/compareGrid.scss`            | The shared grid template + cell primitives                                                                              |
| `Compare/compareLegend.scss`          | Shared legend for the once-per-row composition-bar key                                                                  |
| `Compare/format.ts`                   | Formatters that return `undefined` for missing data instead of `toNumber`'s "N/A"                                       |
| `Compare/highlights.ts`               | `markExtremes(values, direction)` → `("best" \| "worst" \| undefined)[]`                                                |
| `composables/useCompareHardpoints.ts` | One shared per-model hardpoint fetch, cached by slug                                                                    |

Existing `Compare/Models/Row/{index,Label,Value,Title}` get deleted once every section is
migrated — no consumers outside the compare page.

Sections (`Compare/Models/<Name>/index.vue`) stay one component each, keeping today's
declarative `rows` array shape, extended:

```ts
type CompareMetric = {
  key: string;
  label: string;
  direction?: "higher" | "lower"; // omitted ⇒ no winner marking
  raw?: (model: Model) => number | undefined; // comparison value
  value: (model: Model) => string | undefined; // display value
  html?: boolean; // toUEC returns markup
};
```

### Winner marking

`markExtremes` rules:

- needs ≥2 models with a defined `raw` value, otherwise no marks
- all values equal ⇒ no marks (nothing is "best" in a tie of everyone)
- ties at an extreme all get the mark
- a value is never both best and worst
- `direction` omitted ⇒ never marked

Visuals: best = `$gold` + `▴`, worst = `$gray` (dimmed) + `▾`. Worst stays muted rather
than `$danger` — red is reserved for genuine weaknesses (a leaky shield type, armor that
amplifies damage), not for "third-most cargo". Gold on the winning number is consistent
with the established colour semantics: gold = the one headline number per unit.

Directions per row (unambiguous only):

- **higher**: cargo, all speeds & rotation rates, burst/sustained DPS, alpha, weapon count,
  missile damage, shield HP, shield regen, armor HP, hull HP, door HP, container counts,
  max container size, hydrogen/quantum tank, quantum range, weapon power pool, max crew
- **lower**: price, pledge price, min crew, signature cross-section
- **none**: manufacturer, production status, focus, classification, size, length, beam,
  height, mass, part count, and every chip row (multi-valued)

Dimensions and mass are deliberately unmarked — bigger is neither better nor worse.

### Section list & order

1. **Views** — side/top view scale bars (unchanged content, card frame)
2. **Base** — manufacturer, production status, focus, classification, size, L/B/H, mass, cargo, price, pledge price
3. **Crew** — min, max
4. **Speed** — SCM, SCM boosted, max, reverse boosted, pitch/yaw/roll (+boosted); ground rows only when the set contains a ground vehicle
5. **Combat** _(new)_ — burst DPS, sustained DPS, alpha, weapons, missile damage, damage composition bar
6. **Defense** _(new)_ — shield HP, regen, generators, resistances, absorptions, armor HP, deflection, damage reduction, self resistance, signature
7. **Hull** _(new)_ — hull HP, parts, part composition bar, door HP
8. **Cargo** — total SCU, max container size, per-container-size counts
9. **Fuel & quantum** _(new)_ — hydrogen tank, quantum tank, quantum range, weapon power pool, signature cross-section
10. **Hardpoints** — per-group component lists (unchanged content, card frame)

Every section self-hides when no model in the set has data for it, so ship-matrix-only
ships don't leave a row of dashes.

### Data

`Model` already carries `metrics.{hullHealth,hullParts,hullDoors,weaponPoolSize,quantumFuelTankSize,hydrogenFuelTankSize,signatureCrossSection}`, so Hull and most of
Fuel & quantum need no extra request.

Combat and Defense need hardpoints. `Compare/Models/Hardpoints` already fetches them per
model via `Promise.all(fetchModelHardpoints(...))` and refetches _everything_ whenever the
model set changes. Hoist that into `useCompareHardpoints(models)`, called once in
`compare.vue`, cached per slug (adding a 4th ship no longer refetches the other three),
and pass the map down. Source stays per model: game files when `inGame`, else ship matrix.

Stats reuse the already-exported pure functions — no composable refactor needed:
`computeLoadoutStats`, `computeShieldStats`, `computeArmorStats`, `computeHullPartGroups`.
Quantum range follows the established formula (`tank_SCU × 1000 / quantumFuelConsumption`)
off the model's quantum drive hardpoint.

### Shared-component touch-ups

- `MetricsCard`: make the default variant's `__head` flex (`space-between`, centered) so
  the `#head` slot lays out. Currently only `--slim` does; the slot is unused everywhere,
  so this is additive.
- `CompositionBar`: add a `bar-only` prop that suppresses the legend — a full legend per
  ship column would be taller than the rest of the section combined. The legend renders
  once, in the row's label cell.

## Steps — all done

1. ✅ **Grid + primitives** — `compareGrid.scss`, `Section`, `StatRow`, `ChipsRow`,
   `ContentRow`, `highlights.ts` (+ spec), `format.ts`, `MetricsCard` head flex,
   `CompositionBar` `bar-only`.
2. ✅ **Migrated existing sections** — Base, Crew, Speed, Cargo, Views onto the new
   primitives with directions/raw values. `Row/*`, `HeaderImage` and `HeaderTitle` deleted.
3. ✅ **Hardpoint data** — `useCompareHardpoints`, wired through `compare.vue`; the
   duplicate per-section fetch is gone.
4. ✅ **New sections** — Combat, Defense, Hull, Fuel & quantum.
5. ✅ **Header/scroll shell** — sticky ship-name row, `CompareForm` promoted to a toolbar
   above the matrix (it needed more room than a label cell).
6. ✅ **i18n** — new keys under `labels.compare.*`; existing `labels.combat.*`,
   `labels.defense.*`, `labels.hull.*` reused for row labels. English only, matching the
   ship-page cards whose non-en translations are also pending.
7. ✅ **Verify** — `pnpm lint:ts`, `pnpm lint:fix`, `pnpm test` (90 pass), `bin/rails test`
   for the compare-image change, plus an in-browser pass at 2 and 7 ships.

### Also fixed along the way

`CompareImage#build_composite` called `store_image.download` on every attached image, so a
blob row whose file is gone (pruned local storage, a lost object in the bucket) took the
whole compare page down with `ActiveStorage::FileNotFoundError`. It now skips that ship and
logs; if no file survives, no OG image is attached and the page renders unchanged.

## Verified in the browser

Two ships and seven ships, at 1740px: columns 420px, card frames span the full matrix
width, the frozen label rail clears the nav cleanly, section collapse works, and best/worst
markers land where they should.

Sections only appear when the compared ships have the data, which the local dev DB largely
does not: **Hull is absent entirely** (no `hullHealth`/`hullParts`/`hullDoors` rows) and
**Sustained DPS equals Burst DPS** (no `weaponPoolSize`, so the power throttle is 1.0), as
is **cross-section** (no `signatureCrossSection`). Those all come from game-file parsing, so
they need a checkout with parsed SC data — or production — to see for real.

## Open questions

- Non-en translations for the whole metrics-card family are still outstanding; this plan
  does not close that gap.
- Mobile: a matrix this wide is a scroll experience on phones no matter what. 130px labels
  and 280px columns are the mitigation; a card-per-ship mobile fallback is out of scope.
- Hull / sustained-DPS / cross-section rows are unverified against real data for the reason
  above.
