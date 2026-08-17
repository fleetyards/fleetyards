# Hardpoints redesign — metrics-card language + edit-ready slots

Branch: `feat/hardpoints-redesign` (off `feat/loadout-ehp`)
Flag: everything stays behind `hardpoints-v2`.

## Goal

Bring the hardpoint **group list** into the same visual language as the new
Combat / Survivability metric cards, and restructure each hardpoint into a
reusable **slot** row that is built to become the click-target of a future
loadout editor (read-only today).

Design reference: the approved mockup (metrics-card frame, lighter `slim`
variant, recursive slot rows, nested turrets, compact ⇄ expanded density,
neutral size badges, gold = structure / blue = edit-ready).

Non-goals: the sibling Base/Crew/Speed/Cargo panels; any write path / real
editing; the legacy `old.vue` tree.

## Color / token semantics

- **Gold** (`$gold`) — structural/brand accent: card header dot, slot rail.
- **Primary blue** (`$primary`) — interactive / edit-ready only: swap control,
  empty-mount "Fit", hover borders. Inert today.
- **Neutral** (`$gray-light`) — metadata: size badge, `×N` quantity chip.

## Steps

### Step 1 — Extract `<MetricsCard>` (pure refactor, no visual change)
- New `components/Models/MetricsCard/index.vue` owning the frame:
  `.metrics-card`, `__head`, `__title`, `__dot`, `__body`, plus a `variant`
  prop (`default` | `slim`). Props: `title`; slots: default (body) +
  optional `head` (right-aligned header content, e.g. a count).
- `slim` = no `::before/::after` end-caps, single lighter border, reduced
  margin. Purely additive; `default` stays pixel-identical.
- Move the frame rules out of `metricsCard.scss` into MetricsCard's scoped
  style. `metricsCard.scss` keeps the **content** primitives
  (`__hero`, `__tile`, `__section-label`, `__divider`, `__actions`,
  `__breakdown`, `__footer`, `__toggle`, `__hint`) — these style slotted
  content and stay in the consuming card's scope (Vue keeps slotted content
  in the parent component's scope, so the split is clean).
- Refactor `CombatMetrics` + `SurvivabilityMetrics` to wrap their body in
  `<MetricsCard :title="...">`, dropping their hand-written frame markup.
- **Checkpoint:** `useLoadoutStats` / `useShieldStats` specs still green;
  cards render pixel-identical (verify in browser with flag on).

### Step 2 — Hardpoint groups onto the slim card
- `Hardpoints/Group/index.vue`: replace `<h2>` + `<Panel slim>` with
  `<MetricsCard variant="slim" :title="groupLabel">`; category list in body.
- Retune `Group/index.scss` / `new.scss` spacing for cards stacked 2–3 per
  column (they must not read as heavy as the Combat/Survivability cards).

### Step 3 — The slot primitive
- New `Hardpoints/Slot/index.vue` — one mount row: neutral size badge ·
  component name + type/manufacturer sub · `×N` qty · (inert) swap control.
- Empty-mount state: dashed, muted, inert "Fit" affordance.
- Nested children (turret → guns): recursive slot rendered under a gold rail,
  matching the data's nested `hardpoint.hardpoints[]`. Each level swappable.
- Rework `Category` / `Items` / `Item` / `BaseItem` to render slots instead of
  the bespoke `hardpoint-item` markup. Preserve existing behaviours: stacking
  (`count > 1`), details expansion (`typeData`), per-category stat (power pips),
  cargo-grid 3D link.

### Step 4 — Compact ⇄ Expanded density
- Density state in `Hardpoints/new.vue`, `provide`d down; a segmented toggle in
  the header (near the source toggle). Keep the existing per-stack toggle too.
- Compact: identical mounts collapse to one `×N` row. Expanded: fan out to
  individually-labelled (`Mount N`), individually-swappable rows. Applies at
  every nesting level.

### Step 5 — Verify & polish
- Drive the ship page in-browser with `hardpoints-v2` on: groups + cards read
  as one system; nesting, stacking, and the density toggle behave; mobile
  breakpoints hold; empty/loader states intact.
- Run composable specs, `pnpm` prettier + eslint. Fix any new i18n label keys.

## Commits (small, focused)
1. exec-plan
2. extract `<MetricsCard>` + refactor the two cards (no visual change)
3. hardpoint groups → slim card
4. slot primitive + Category/Item rework
5. compact/expanded density toggle
6. polish / i18n / lint
