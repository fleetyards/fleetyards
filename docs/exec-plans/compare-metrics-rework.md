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

### Row geometry — the old design's flex sizing, kept

Settled after three rounds of user feedback (2026-08-12/13). The rows keep the **old
compare page's sizing recipe**, only wrapped in the new card frames:

```scss
.compare-cell {
  flex: 1 1 0;
  min-width: 450px;
  max-width: 33%;
}
.compare-cell--label {
  flex: 0 0 300px;
  max-width: 20%;
}
```

`flex: 1 1 0` makes every column the same width regardless of content, so columns still
line up across separate section cards — the property a grid was originally chosen for.

**Why not a grid of fixed tracks** (two attempts, both rejected by the user):

- A grid track has to be sized up front, and **no single width serves both** a three-digit
  number and a hardpoint item row (size badge + name + manufacturer + inline stat strip +
  nested loadout rail). At 420px the hardpoint rows overflowed and `overflow: hidden` cut
  component names mid-word ("Tempes / II Missil / Firestor"), with damage figures colliding
  with names. 450px + no clipping is what the old design had, and it worked.
- `1fr` tracks size against content, so the store images' intrinsic width stretched a
  two-ship comparison to ~1000px per column. The `max-width: 33%` cap solves the same
  problem without the blowup — that cap is why the old design never looked too wide.

### The matrix scrolls in its own pane

Both axes are pinned, each on one axis only: the **ship-name row sticks vertically**, the
**label column sticks horizontally**. Getting there took three attempts, and the final
architecture — user-chosen 2026-08-13 — is a height-capped `overflow: auto` pane around the
card stack, rather than letting the document scroll sideways.

Why the pane, and not document-level scroll:

- **The footer and chrome cut off.** Content overflowing the document extends the scrollable
  area but does not stretch siblings, so the footer ended at viewport width with the page
  background showing beyond it. Same for the right-hand gap to the container edge.
- **The frozen label column had to dodge the nav.** The page scrolls underneath the fixed
  navigation rail, so `left: 0` parked the labels behind it; it needed an offset of the nav's
  width (300px, 80px slim, read from `navStore.slim`) _plus_ an opaque slab painted over the
  strip beside it, because the nav is translucent and the columns showed through as torn-off
  text. In a pane, `left: 0` is simply the pane's edge — offset and slab both deleted.

And the bug that made the first attempt look half-broken: **`position: sticky` can only
travel inside its parent's box.** The name row was nested in a `.compare-header` wrapper
~250px tall, so it scrolled away instantly (measured at `top: -5737px`) while the label rail
stayed pinned. The Header component now renders its two rows as siblings of the section
cards — no wrapper — so the name row can travel the whole pane.

The pane's height is measured on mount and resize (`getBoundingClientRect().top + scrollY`)
rather than hard-coded, because the toolbar above it wraps at narrow widths.

Trade-off accepted: a nested scroll area, so there is a second vertical scrollbar while the
pointer is over the matrix. `overscroll-behavior: contain` stops the gesture chaining to the
page mid-comparison.

### Components

| Path                                  | Role                                                                                                                    |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `Compare/Models/Section/index.vue`    | Section frame: `MetricsCard` + collapse toggle in the (currently unused) `#head` slot, `Collapsed` body, `hasData` gate |
| `Compare/Models/StatRow/index.vue`    | One metric row: label cell + one value cell per model, best/worst classes                                               |
| `Compare/Models/ChipsRow/index.vue`   | Multi-valued row (resistances, absorptions, deflection, reduction) reusing DefenseMetrics' chip look                    |
| `Compare/Models/ContentRow/index.vue` | Per-model slot row for composition bars, silhouettes and hardpoint group lists                                          |
| `Compare/Models/Header/index.vue`     | Full-bleed 242px store image + corner remove button per ship, plus the ship-name row                                    |
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

## Approved redesign (2026-08-14) — supersedes the layout above

Mockup, signed off: https://claude.ai/code/artifact/c26cb0c7-01e4-45e5-99e4-46b7bd7d02e0

The patched-up version reached "I'm really torn": the best/worst marks and the reused bars
and pills were liked, the sticky behaviour and the compressed hardpoints were not. The
mockup resolves it. What survives from the current code: `CompareMetric`, `markExtremes`,
`useCompareFormat`, `useCompareHardpoints`, and the per-section metric definitions. What goes:
`Section`, `StatRow`, `ChipsRow`, `ContentRow`, `Header` and the per-section `MetricsCard`
frames.

**One continuous `<table>`, no card per section.** A real table, `border-collapse: separate`,
`table-layout: fixed`, `<col>` widths. Sticky lives on `th`: `thead th { top: 0 }`,
`tbody th { left: 0 }`, corner cell gets both plus the highest z-index. This is the canonical
pattern and it is why the rail no longer fights anything — a card frame per section was a box
the frozen rail had to sit on top of, and it slid out from underneath.

Section bands are rows _inside_ the table (`tr.band`), and the band title lives in the rail
cell. Emergent win: scrolled far right you keep both the metric name and the section name.

**Widths:** `--railw: 232px`, `--col: 212px` comfortable / `176px` dense. 212px is what a
hardpoint component tile needs; the dense mode is what fits eight columns without sideways
scroll.

**Condensing header.** Store art 104px tall at rest, collapsing to name + manufacturer once
`pane.scrollTop > 24`. Keeps the silhouette (which is half of what identifies a column)
without a permanently tall header. Header text is right-aligned to match the figures below —
`th` centres by default, which is what made short names left-align and long ones look centred.

**Loadout compares by slot, using the hardpoint components.** Rows are slot classes (main
guns, turrets, missiles, shield generators, power plant, coolers, quantum drive); each cell is
the real hardpoint item tile — size badge, component name × qty, manufacturer, one headline
stat in gold, primary-blue left rail. This is the fix for the width problem at its root:
eight parallel lists were never a comparison, and each list wanted ~450px.

**Every comparable figure carries a relative bar** (share of the row's max), because eight
numbers in a row is past what the eye ranks unaided. Gold stays the single headline number,
blue stays structural — unchanged colour semantics.

**Two noise filters, both only worth it at this width:** _Differences only_ drops rows where
every ship agrees; _Compare to baseline_ turns figures into ±% against one chosen column
(click ◎ in a header). Plus the density toggle.

Views keep their scaled side/top silhouettes, scaled against the longest ship on screen.

### Blocked on the button / panel rework (2026-08-14)

The rebuild waits for the in-flight button and panel reworks rather than racing them. Measured
overlap against `feat/btn-redesign` (220 files, pushed): **exactly one shared file**,
`Compare/Models/Form/index.scss`. So rebasing later is cheap — this is a sequencing choice,
not a merge-risk one.

Where the coupling actually is:

- **Buttons — real.** The compare toolbar is `Btn` / `BtnGroup` / `ShareBtn` / `ModelFilterGroup`,
  and `feat/btn-redesign` rewrites `Btn/index.vue` and `Btn/types.ts`. This branch already
  dropped the `block` prop from the compare form's buttons to make them a toolbar; that edit
  needs revisiting against the new prop API on rebase.
- **Panels — small, and shrinking.** `feat/btn-redesign` does not touch `base/Panel` or
  `MetricsCard` (only `panel-btn` styles and a few feature panels), and no `panel-redesign`
  branch exists yet. More to the point, the approved redesign _removes_ compare's dependence
  on panel frames — one continuous table, no card per section — so a panel rework's blast
  radius here is much smaller than it would have been against the patched version.
- **Inherited for free:** compare reuses `CompositionBar` and the chip/pill styling, so
  whatever the panel rework does to those, compare picks up automatically. That is the
  intent.

Preferred order: let `feat/btn-redesign` land on `main`, rebase this branch onto `main`, then
run the rebuild steps below. Stacking directly on the unmerged branch is possible (the
hardpoints redesign did exactly that) but only worth it if buttons stay unmerged for a while.

### Rebuild steps

1. `CompareTable` — one component rendering `<colgroup>/<thead>/<tbody>` from the section +
   row model; move `compareGrid.scss` to table selectors, delete the flex cell classes.
2. Cell renderers for `num` (with bar + marks), `text`, `pills`, `comp`, `view`, `fit`.
3. `CompareHeader` → `<thead>` with the condensing art and per-column baseline/remove actions.
4. Loadout: group the fetched hardpoints by slot class instead of by `HardpointGroupEnum`,
   and render the item tile per cell.
5. Toolbar: density, differences-only, baseline mode.
6. Drop `Section`, `StatRow`, `ChipsRow`, `ContentRow` and the pane/flex CSS they carried.

## Steps — all done

1. ✅ **Grid + primitives** — `compareGrid.scss`, `Section`, `StatRow`, `ChipsRow`,
   `ContentRow`, `highlights.ts` (+ spec), `format.ts`, `MetricsCard` head flex,
   `CompositionBar` `bar-only`.
2. ✅ **Migrated existing sections** — Base, Crew, Speed, Cargo, Views onto the new
   primitives with directions/raw values. `Row/*`, `HeaderImage` and `HeaderTitle` deleted.
3. ✅ **Hardpoint data** — `useCompareHardpoints`, wired through `compare.vue`; the
   duplicate per-section fetch is gone.
4. ✅ **New sections** — Combat, Defense, Hull, Fuel & quantum.
5. ✅ **Header shell** — ship-name row plus the old design's full-bleed 242px store image
   and corner remove button; `CompareForm` promoted to a toolbar above the matrix (it
   needed more room than a label cell).
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
  and 300px columns are the mitigation; a card-per-ship mobile fallback is out of scope.
- Hull / sustained-DPS / cross-section rows are unverified against real data for the reason
  above.
