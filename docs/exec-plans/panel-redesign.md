# Panel component redesign

## Goal

Rebuild `shared/components/base/Panel` and its sub-components on the metrics-card
visual language, so panels, buttons and metrics panes read as one surface system,
and fold `MetricsCard` into `Panel` instead of maintaining a second card
implementation alongside it.

Companion to [`btn-redesign.md`](btn-redesign.md). That plan chose the
metrics-card language for the app's controls (its D6) and built the token and
build-pipeline groundwork this one reuses. Branch stacks on `feat/btn-redesign`.

## Context

Measured surface (census over `app/frontend`, `*.vue`):

| Metric                                            | Count        |
| ------------------------------------------------- | ------------ |
| `<Panel>` call sites                              | 91           |
| Files containing `<Panel>`                        | 44           |
| Further instances via wrapper components          | 116          |
| `<PanelHeading>` / `<PanelBody>` / `<PanelImage>` | 67 / 66 / 11 |
| `<MetricsCard>` call sites                        | 11           |
| Files restyling `.panel*` from outside            | 6            |
| Playwright specs coupled to panel internals       | **4**        |

The 116 indirect instances come from five components that wrap `Panel`:

```
StatsPanel 69   BaseTable 36   Box 6   AppModal 3   TeaserPanel 2
```

Prop usage on the 91 direct sites, ordered:

```
23 slim         17 class        11 fill-height   8 alignment
 7 inset         7 variant       6 transparency  4 bg-image
 3 shadow        3 id            2 bg-color      2 outer-spacing
 2 bg-rounded    2 animated      2 highlight
```

Value distribution:

```
variant:       error 3 | success 2 | primary 1        (+1 dynamic)
transparency:  more 6                                 (complete: 0)
bg-color:      primary 2                              (admin: 0)
shadow:        top 3                                  (left/right/bottom: 0)
alignment:     left 7 | right 1
```

## Findings that drive the design

### F1 — The app already has two competing surface systems

`MetricsCard` was built at the current design's edge rather than inside it, and
`btn-redesign` then adopted _its_ language for every control in the app. Panel is
now the only major surface still speaking the old one:

|             | `Panel`                                 | `MetricsCard`                    |
| ----------- | --------------------------------------- | -------------------------------- |
| Frame       | 2px outer + 3px inner border, two boxes | one 2px border                   |
| Edge colour | `rgba(#c8c8c8, .9)`                     | `rgba($gray-light, .5)`          |
| Radius      | 24 / 20 / 16px                          | 16px                             |
| End-caps    | 4 hairlines, `#444`, fixed 40px + 80px  | 2 hairlines, `#4a4f54`, r1px     |
| Shadow      | `0 1px 1px rgba(#000,.05)`              | `0 6px 18px -12px rgba(#000,.8)` |
| Title       | `Heading` hero, 2.25rem                 | Orbitron 15px, `.2em`, gold dot  |
| Motion      | `$transition-base-speed` (**500ms**)    | `150ms ease`                     |

Eleven metrics cards sit on the ship page inside and beside panels, so the two
systems are visible in the same viewport.

### F2 — The double frame is the dated signature

`.panel-wrapper` (2px border, 24px radius, 2px padding) wraps `.panel` (3px
border, 20px radius), which wraps `.panel-inner` (16px radius). Four borders and
5px of chrome for one surface — and **four** `::before`/`::after` hairlines, two
on the wrapper and two on the panel, at different insets.

Collapsing to a single box is what makes a single pair of end-caps possible, and
it is the change that does most of the visual work.

### F3 — Fixed cap insets collapse on narrow panels

The same defect `btn-redesign` fixed for buttons (its D5). Wrapper caps are inset
80px per side, panel caps 40px, so the two pairs are concentric at different
fractions of the width and stop reading as one motif as the panel narrows:

| Panel width                | Outer cap (W − 160) | Inner cap (W − 88) |
| -------------------------- | ------------------- | ------------------ |
| 600px (`col-md-7`)         | 440px (73%)         | 512px (85%)        |
| 290px (`col-md-4` at `md`) | 130px (**45%**)     | 202px (70%)        |
| 258px (`col-sm-6` at `sm`) | 98px (**38%**)      | 170px (66%)        |
| 160px                      | **0px — invisible** | 72px               |

`col-md-4` is used at 12 panel sites and `col-lg-4` at 6, so the 45% case is
live, not hypothetical.

### F4 — `slim` is the real default

`.panel-inner` ships `min-height: 286px`; `slim` sets it to 0.

`slim` is passed at 23 of 91 direct sites — but **all five** wrapper components
pass it, and they account for 116 further instances. Effective split is **139
slim to 68 not**, and the 68 fall into three groups:

- **37** are chart or stat tiles in Bootstrap rows (`stats.vue` 8, `FleetStats` 7,
  `hangar/stats` 5, `PublicFleetStats` 5, `PublicHangarStats` 4, admin dashboard
  7, …), where the height is really the chart's requirement.
- **The card components** — `Models/Panel`, `Modules/Panel`,
  `Fleets/Logistics/InventoryPanel`. Three call sites, but `Models/Panel` is the
  ship card: `ModelPanel` and `VehiclePanel` between them appear at 13 sites and
  render up to 48 cards per page inside `base/Grid`. **This is where the floor is
  load-bearing** — see below.
- The remainder are prose pages (impressum, privacy policy, API docs) whose
  content clears 286px unaided, so the min-height never applies.

**The card grid is the case to get right.** `base/Grid` is a Bootstrap `.row`
with `col-12 col-md-6 col-lg-4 col-xl-3 col-xxl-2dot4 col-3xl-2`. Columns stretch
to the tallest in the row, but the `Panel` inside is not `height: 100%` —
`Models/Panel` does not pass `fill-height` — so today the cards line up _only_
because of the 286px floor. Remove it naively and the ship grid goes ragged.

That does not rescue the floor; it identifies what it is standing in for. 286px
is wrong in both directions: a row of short cards is held open to 286px it does
not need, and a card with a wrapping title already overflows past its neighbours.
`fill-height` equalises to the tallest card in the row, which is what the grid
actually wants. See D5.

No site wants a 286px floor _as a panel property_. This is `btn-redesign`'s F1
again: the component's default is not the one the app asks for.

### F5 — `outerSpacing` is **not** the button's margin problem

Worth stating explicitly, because the reflex after `btn-redesign` is to strip the
margin. `Panel` ships `margin-bottom: 21px`, opted out at **2** sites.

The button case was the opposite — 112 sites passing `inline` purely to cancel
`margin-bottom: 20px` — because a button is an inline control dropped into flex
rows that already own `gap`. A panel is a block-level surface stacked vertically,
and 89 of 91 sites want the gap. **The default stays.**

The genuine defect is the coupling it forces:

```scss
&--fill-height {
  height: 100%;
  &.panel-wrapper--outer-spacing {
    height: calc(100% - 21px);
  }
}
```

`fill-height` (11 sites) has to subtract the margin from its own height. That
arithmetic goes; the margin does not.

### F6 — Dead and no-op API

Measured across all call sites:

| Member                               | Sites  | Status                                                                        |
| ------------------------------------ | ------ | ----------------------------------------------------------------------------- |
| `PanelBody` `noMinHeight`            | **16** | **no-op** — no class in the map, no rule in the stylesheet                    |
| `PanelHeading` `title-align`         | **4**  | **no-op** — not a declared prop; lands on the root `div` as a stray attribute |
| `PanelHeading` `multiline`           | **4**  | **no-op** — same                                                              |
| `PanelHeading` `hero`                | 0      | declared, never read (template hardcodes `hero` on `Heading`)                 |
| `to` + `linkLabel` (`PanelLink`)     | **0**  | dead — the only use is Panel's own template                                   |
| `bgOverlay`                          | 0      | dead                                                                          |
| `bgAlign` / `PanelBgAlignmentsEnum`  | 0      | dead                                                                          |
| `PanelTransparenciesEnum.COMPLETE`   | 0      | dead (`MORE` has 6)                                                           |
| `PanelBgColorsEnum.ADMIN`            | 0      | dead (`PRIMARY` has 2)                                                        |
| `PanelShadowsEnum` LEFT/RIGHT/BOTTOM | 0      | dead (`TOP` has 3)                                                            |
| `PanelBody` `noPadding`              | 0      | dead                                                                          |

Twenty-four call sites pass a prop that does nothing at all. `PanelBody` also
declares its corner type as `PanelImageRounded`, a copy-paste duplicate of
`PanelBgRoundedEnum`.

### F7 — `noPaddingTop` is a symptom of the padding pair, not a feature

`PanelBody` `noPaddingTop` is passed at 12 sites. `PanelHeading` pads
`15px 15px 0` and `PanelBody` pads `15px`, so heading-then-body stacks 15px of
body padding under a heading that already closed flush. Every one of the 12 is
cancelling that.

MetricsCard got the pair right — head `16px 18px 12px`, body `4px 18px 18px` —
which is why no metrics card needs the equivalent escape hatch.

### F8 — The embed bundle, again

`stylesheets/embed/partials/panel.scss` is a **259-line near-complete duplicate**
of the panel styles (wrapper, panel, heading, image, inner), for exactly the
reason `btn-redesign`'s F7 documents: `app/views/frontend/embed.js.erb` links one
stylesheet, `embed.scss` namespaces under `#fleetyards-view` and does not import
Tailwind.

This needs no new investigation. `btn-redesign`'s D3 established and empirically
verified the resolution — author the surface in a **plain `<style scoped>` block**
(not `lang="scss"`, under which `@reference` and `@apply` are silently dropped by
the minifier) so utilities inline at build time with custom-property fallbacks,
leaving self-sufficient plain CSS the embed can consume. Panel inherits that
decision.

### F9 — Test coupling is thin but, unlike the button's, not zero

`btn-redesign` had zero tests touching `panel-btn`. Panel has four:

- `Home.spec.ts` locates panels by class — `getByTestId("home-ships").locator(".panel")`
- `panel-heading-title` is used as a test id in `Home`, `Hangar`, `Ships`, `Ship`

So the `.panel` class name and the `panel-heading-title` hook are contract and
must survive the rebuild. `base/Panel/index.spec.ts` is 10 lines.

One thing that is _better_ than the button's starting point:
`frontend/pages/visual-tests/panels.vue` already exists at 417 lines and covers
variants, alignments and bg-colors. It needs extending, not building.

### F10 — A solid button on a panel is the same fill as the panel

Surfaced by doing this work after `btn-redesign`, and worth flagging before the
button PR merges:

```
$panel-bg          = rgba($gray-darker, .9) = rgb(39 43 48 / .9)
--color-control    =                          rgb(39 43 48 / .9)
```

Byte-identical. A `variant="solid"` button sitting on a panel is distinguished
from its background only by its edge and end-caps. See Q1.

### F11 — Outside-in restyling is smaller than a grep suggests

A grep for `.panel*` outside the component finds six files. Reading them, **only
the embed pair is real**:

| File                                                 | Verdict                                                        |
| ---------------------------------------------------- | -------------------------------------------------------------- |
| `embed/components/Models/Panel/index.vue`            | real — the embed's own card, `.panel-inner` / `.panel-heading` |
| `stylesheets/embed/partials/panel.scss`              | real — the 259-line F8 duplicate                               |
| `frontend/pages/fleets/preview.scss`                 | **false positive**                                             |
| `frontend/pages/hangar/preview.scss`                 | **false positive**                                             |
| `frontend/components/Fleets/VehiclePanel/index.scss` | **dead file**                                                  |

The two preview pages never touch the component. They hand-roll
`<div class="panel-heading">` and `<div class="panel-body">` _inside_ a `Panel`
and style those, borrowing the class names but getting nothing from
`PanelHeading`/`PanelBody`, whose styles are scoped. `.panel-title` there is a
real global in `stylesheets/shared/typography.scss`. Nothing to un-leak.

`VehiclePanel/index.scss` was 81 lines positioning an `.on-sale` badge and a
`.panel-add-to-hangar-button` inside `.panel-image` / `.panel-heading`. Neither
class is rendered anywhere — `Models/Panel` calls them `model-panel-on-sale` and
`model-panel--add-to-hangar-button` — and the file was not imported by anything,
including the component beside it. Deleted rather than migrated.

So the button redesign's 17 leaked stylesheets have no real counterpart here. The
one genuine coupling left is the embed's parallel implementation, which is F8's
problem, not a leak.

### F12 — Tables get the frame for free, and their interior then out-shouts it

Both table implementations wrap `Panel`:

```
BaseTable       36 sites, 31 files   <Panel :id class="base-table w-full" :slim="true" :fill-height>
BaseTable2       4 sites,  1 file    <Panel :id class="base-table w-full" slim>
```

So the tables take the new frame with **no edits at the call sites** — after
`StatsPanel`, the largest single beneficiary of the redesign.

**`BaseTable2` has no production call sites.** All four are
`visual-tests/tables.vue`. It is a div-and-CSS-grid rewrite with ARIA roles
(`role="table" / "row" / "columnheader"`) against `BaseTable`'s real
`<table>`/`<thead>`/`<tr>`/`<td>`, added in the Vue 3 migration (#2655,
2026-03-31) and untouched since apart from a repo-wide dependency commit, while
`BaseTable` kept taking feature work into May. Its props are a strict subset —
it lacks `admin`, `asyncStatus`, `fillHeight`, `rowClickable` and `rowDisabled` —
and it imports `SortableLink` and `BulkActions` from `Table`, so it is not
standalone either. It is a parked prototype, not a migration in flight.

Their _interiors_ are untouched by this plan, and two things then read louder
than the frame containing them:

- **The row hover rail.** `Table/Col` and `Table2/Row` both draw a 4px `$primary`
  bar on hover with a **triple box-shadow glow**:
  ```scss
  box-shadow:
    3px 0 10px rgba(darken($primary, 20%), 0.9),
    0 3px 10px rgba(darken($primary, 20%), 0.9),
    0 -3px 10px rgba(darken($primary, 20%), 0.9);
  ```
  The metrics language has the same device at `metrics-card__tile--primary` — a
  3px `linear-gradient($primary, rgba($primary, .15))` rail, no glow. Same idea,
  very different intensity. Once the panel around it goes quiet, the glow is the
  loudest thing left on the page.
- **The header rule and label.** `Table2/Header` uses `border-bottom: 1px solid
$gray` (`#52575c`, solid) where the metrics language uses
  `rgba($gray-light, .28)`; header cells are `darken($text-color, 20%)` +
  `font-weight: bold` in Open Sans, against metrics labels' Orbitron 10px
  `.16em` uppercase.

`Table2/Row`'s rail is a copy-paste of `Table/Col`'s, so the glow exists twice —
but since `Table2` ships to nobody, interior work targets `Table` alone and the
duplicate only matters if `Table2` is kept. See Q8 and Q9.

### F13 — `slim` collides with itself in the new API, and tables are where it bites

A codemod hazard created by D6, worth naming before it is written. Today `slim`
means _no 286px min-height_. In the new API `variant="slim"` means something
entirely different — a 1px edge at radius 12 with **no end-caps**.

A mechanical `slim` → `variant="slim"` rename would silently strip the caps and
thin the border on every table, `StatsPanel`, `Box`, `AppModal` and
`TeaserPanel` in the app — the five wrappers all pass it (F4), which is 116
instances, plus 23 direct sites.

The correct migration is the opposite: `slim` is **deleted**, because D5 makes
its behaviour the default. Nothing maps to `variant="slim"`; that variant is new
and opt-in.

## Decisions

### D1 — `MetricsCard` becomes a `Panel` composition, not a parallel surface

The unification runs in the direction that deletes code: the **frame** moves into
`Panel` (F1's table is a list of values Panel adopts), and `MetricsCard` keeps
only what is genuinely card-local — the Orbitron title with its gold dot, and the
content primitives in `metricsCard.scss` (`__hero`, `__tile`, `__row`, `__aux`,
`__divider`).

```
MetricsCard  →  <Panel variant="default" tone="neutral">
                  <PanelHeading tone="metric" :dot="…">
                  <PanelBody>          ← slotted tiles/rows keep metricsCard.scss
```

`metricsCard.scss` stays where it is and keeps its scope comment: those classes
style slotted content and must resolve in the consumer's scope.

Consequence in the useful direction: the proportional cap inset from D3 reaches
the metrics cards too, fixing a defect they have but have not yet hit, since
`Hardpoints/Group` renders `--slim` cards in narrow columns.

### D2 — One box, one border

Delete `.panel-wrapper` from the DOM. `.panel` becomes the single frame:

```
border:        2px solid var(--color-edge)       /* rgba($gray-light, .5) */
border-radius: var(--radius-surface)             /* 16px */
background:    var(--color-surface)              /* $panel-bg, unchanged */
box-shadow:    0 6px 18px -12px rgba(#000, .8)
transition:    150ms ease                        /* was 500ms */
```

All five values are MetricsCard's, not new. `.panel` keeps its class name per F9.
Tone borders and the error/success animations move off the deleted wrapper onto
`.panel`.

`.panel-inner` survives only where it earns its keep — `alignment` (8 sites) needs
a row context, `inset` (7) a padding context — and loses its `min-height` per D5.

### D3 — End-caps: one pair, proportional inset

Adopt `btn-redesign`'s D5 formula at panel scale, and turn the cap up — the
first revision inherited MetricsCard's values unchanged and they read as a
smudge rather than a signature.

**Settled from the review rig:**

```css
left: max(10px, 12%);
right: max(10px, 12%);
height: 4px;
background: var(--color-endcap); /* #7a8288 */
border-radius: 0 0 3px 3px; /* ::before — inward edge only */
border-radius: 3px 3px 0 0; /* ::after  — inward edge only */
```

No end fade. The cap holds ~76% of the width at any width, against the 38–45%
(and 0%) that F3 measures today. One pair replaces four hairlines.

**`--color-endcap` moves from `#4a4f54` to `$gray-light` `#7a8288`.** The old
value sits 3–5 points of luminance above `$panel-bg`'s `rgb(39 43 48)`, so the
motif that is supposed to be the frame's signature is the least visible thing on
it. At `#7a8288` the cap becomes the brightest element of the frame, which is
what a signature should be, and it matches `--color-edge` at full opacity rather
than introducing a sixth grey.

Two consequences worth naming:

- The token is **shared with the buttons**. `btn-redesign` already ships
  `--color-endcap`, so raising it changes #4338's buttons in the same commit
  range. That is the desired outcome — a panel cap and a button cap must read as
  the same motif — and it is only cheap while #4338 is open. Button cap
  _heights_ stay one step below the panel's (2px, 3px at `lg`), since a 43px
  control cannot carry a 4px hairline.
- `variant="slim"` still carries no caps, following `metrics-card--slim`. Once
  the cap is this much louder, a grid of repeated slim cards is exactly where it
  would become noise.

**The radius goes on the inward edge only** — and this is a detail the current
`Panel` already has that both newer components dropped:

```scss
// Panel/index.scss, today
&::before {
  border-bottom-right-radius: 1px;
  border-bottom-left-radius: 1px;
}
&::after {
  border-top-left-radius: 1px;
  border-top-right-radius: 1px;
}
```

The top cap rounds its _bottom_ corners and the bottom cap its _top_ corners, so
the outward edge stays a crisp line continuous with the border while the side
facing into the panel softens. `MetricsCard` (`border-radius: 1px`) and #4338's
`Btn` (`rounded-[1px]`) both round all four corners and lose the distinction; the
redesign carries the original behaviour forward rather than inheriting theirs.

```css
::before {
  border-radius: 0 0 var(--cap-r) var(--cap-r);
}
::after {
  border-radius: var(--cap-r) var(--cap-r) 0 0;
}
```

Rounding one edge also lifts the clamp. A radius is limited by the sum of the two
radii sharing a side, so with the opposite corner at `0` it can run to the **full
cap height** rather than half it — up to `4px` on a 4px cap, twice the range an
all-corner radius allows. Settled at `3px`: softened, but stopping short of the
full half-round, which starts to read as a lozenge floating on the edge rather
than as part of it.

**Buttons take the radius scaled, then ceilinged.** Their cap is 2px tall against
the panel's 4px, so the panel's `3px` would clamp to a full round there and the
two would stop being proportional. The radius steps down by the same ratios the
heights already do — and is then held to **half its own cap height**, because the
proportional step alone still lands at `1.5px` on a 2px cap, close enough to a
full inward round that the bar reads as a lozenge rather than a seam.

```
--cap-h-btn:    max(2px, --cap-h - 2px)                         2px    sm / md, BtnGroup track
--cap-h-btn-lg: max(2px, --cap-h - 1px)                         3px    lg

--cap-r:        3px                                                    panel (4px cap, 0.75×)
--cap-r-btn:    min(--cap-r × 0.5,  --cap-h-btn / 2)            1px    ← ceiling binds (1.5 → 1)
--cap-r-btn-lg: min(--cap-r × 0.75, --cap-h-btn-lg / 2)         1.5px  ← ceiling binds (2.25 → 1.5)
```

The ceiling binds at both button sizes today, so the effective rule is simply
_half the cap height_; the proportional term is what keeps it from exceeding the
panel's own ratio if `--cap-r` is ever lowered.

The panel keeps `0.75 ×` its cap height rather than taking the same ceiling. Its
cap is twice as tall, so a `2px` radius there reads as under-rounded — the
asymmetry is deliberate, not an oversight. If the half-height rule should govern
everywhere, `--cap-r` becomes `2px` and this paragraph goes.

Deriving rather than hard-coding means a later change to `--cap-r` keeps all
three in step, which is the failure mode that let `MetricsCard` and `Btn` drift
to all-corner rounding in the first place.

#### What this changes in #4338's rendering

Three edits to `Btn`'s cap block. Nothing else about the button — sizes,
variants, tones, hover, focus, `BtnGroup` — is touched.

|        | #4338 today                        | After                                      | Why                                                                                                                              |
| ------ | ---------------------------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| Colour | `--color-endcap: #4a4f54`          | `#7a8288`                                  | Shared token. `#4a4f54` sits 3–5 points of luminance above the control fill, so the motif is the least visible part of the frame |
| Inset  | `max(10px, 18%)`                   | `max(10px, 12%)`                           | Panel and button read as one motif only at one inset                                                                             |
| Radius | `rounded-[1px]` — all four corners | inward edge only, `1px` sm/md · `1.5px` lg | Restores what `Panel/index.scss` does and `Btn` dropped                                                                          |

**Cap heights do not change.** 2px at `sm`/`md` and 3px at `lg`, exactly as
#4338 ships them — `max(2px, --cap-h - 2px)` and `max(2px, --cap-h - 1px)`
evaluate to those at the settled `--cap-h: 4px`. The 10px floor is unchanged too.

The inset change is width-dependent, because the floor governs narrow buttons:

```
  43px (icon-only sm)   64% → unchanged   floor binds at both insets
  55px                  64% → unchanged   floor binds at both insets
  83px                  64% → 76%         +9.9px
 120px                  64% → 76%         +14.4px
 200px                  64% → 76%         +24.0px
```

The floor binds below 55.6px at 18% and below 83.3px at 12%. So icon-only and
very short buttons are visually untouched by the inset change; labelled buttons
gain 10–24px of cap.

Practical consequence for #4338: its own description states the cap "holds a
constant ~64% of the width at any label length". That figure becomes ~76% for
labelled buttons, and the matrix screenshots in the PR body are re-shot.

**Rejected: fading the ends.** A horizontal gradient
(`transparent → endcap 16% → endcap 84% → transparent`) was reviewed as an
alternative way to make the cap less hard. It costs the cap a measurable length,
which undercuts the "constant 76% of the width" property this whole decision
rests on. The inward radius achieves the softening without that trade. If anyone
later reaches for a gradient fill here, this is why it was passed over.

### D4 — Build pipeline and tokens inherited from `btn-redesign`

Plain `<style scoped>` with `@reference` + `@apply`, per F8 and `btn-redesign`'s
D3. `Panel` drops `@import "index"` and the auto-injected SCSS variables.

Most tokens already exist in `@theme` from the button work — `--color-edge`,
`--color-edge-soft`, `--color-endcap`, `--color-lifted`. Added here:

```
--color-surface:        rgb(39 43 48 / 0.9)   /* === $panel-bg; see F10/Q1 */
--radius-surface:       16px
--radius-surface-slim:  12px
--shadow-surface:       0 6px 18px -12px rgb(0 0 0 / 0.8)
```

### D5 — The 286px min-height goes to the content that wants it

Default is no min-height; the `slim` prop is **removed** rather than inverted, so
no call site carries the concept. Per F13, nothing maps to `variant="slim"` —
that is a different thing that happens to share the word.

The 68 sites that relied on the floor are re-homed by group:

| Group                                                          | Was                 | Becomes                                                  |
| -------------------------------------------------------------- | ------------------- | -------------------------------------------------------- |
| Card grids — `Models/Panel`, `Modules/Panel`, `InventoryPanel` | 286px floor         | `fill-height`, equalising to the tallest card in the row |
| Chart and stat panels (37)                                     | 286px floor         | no change needed — `Chart` already owns 400px, see Q2    |
| Prose pages                                                    | floor never applied | nothing                                                  |

The card change is an improvement rather than a port: 286px is simultaneously too
tall for a row of short cards and too short for one with a wrapping title, which
overflows its neighbours today.

This is the one change in this plan that is not mechanically
behaviour-preserving — the same status `btn-redesign`'s D1 had — so it is
reviewed on `visual-tests/panels.vue` before the codemod runs, **with the ship
grid at `col-lg-4` and `col-3xl-2` specifically**, since that is where a
regression would be most visible and least likely to show up in a unit test.

### D6 — `variant` × `tone`, mirroring the button's D2

Today three separate props carry appearance: `variant` (`default|primary|success|error`)
mixes surface with meaning, `highlight` is a fourth meaning as a boolean, and
`bgColor` is a fifth axis that fills rather than outlines.

```
variant: default | slim | bare        (how much chrome)
tone:    neutral | primary | success | error | highlight   (what it means)
```

- `default` — 2px edge, 16px radius, caps, shadow
- `slim` — 1px edge, 12px radius, no caps, quieter shadow (`metrics-card--slim`)
- `bare` — background only, no edge/caps/shadow; absorbs `transparency`

**Tone is carried by the end-cap, not the edge — decided in review.** The first
revision recoloured the whole border, which makes a validation error the loudest
thing in the viewport and throws away the quiet neutral frame the rest of this
plan exists to get. Three treatments were compared in the rig — edge, whole cap,
and a 1–2px line along the cap's outward face — and the **whole cap** won:

```css
.panel--error {
  --tone: #c00;
}
.panel--error::before,
.panel--error::after {
  background-color: var(--tone);
}
```

The frame stays `--color-edge` at every tone. Each tone declares only `--tone`, so
the treatment lives in one place.

Two consequences:

- **`slim` has no caps**, so its edge has to take the tone instead. One tone
  therefore reads two ways depending on variant. Accepted rather than solved:
  giving slim caps back would undo the reason it exists, and a grid of repeated
  slim cards is where a loud cap becomes noise.
- The `animated` error/success states pulse the cap's opacity rather than
  interpolating a border colour, so one pair of keyframes serves every tone.

**The button's tone does not move with it**, and the asymmetry is deliberate:

|         | carries tone via                    | why                                                            |
| ------- | ----------------------------------- | -------------------------------------------------------------- |
| `Panel` | the end-cap                         | it has no text of its own; the title belongs to `PanelHeading` |
| `Btn`   | the label (`#f0a8ae`) plus its edge | it does, and the label survives every variant                  |

A cap-carried tone would vanish on `bare`, `grouped` and `menu-item`, which all
set `content: none` on their caps — and `menu-item` is where destructive actions
mostly live, so danger would go dark exactly where it matters. Scale compounds
it: 4px of cap on a surface hundreds of pixels wide reads; 2px on a 43px control
signatures but cannot carry meaning.

So each component uses the channel it has. What is shared is the cap's colour and
geometry, already unified through `--color-endcap` and the `--cap-*` tokens.

There is no filled counterpart to tone — see D9.

Mapping: `variant="error"` → `tone="error"`, `highlight` → `tone="highlight"`,
`transparency="more"` → `translucent` (6 sites), `transparency="complete"` →
`variant="bare"` (0 sites), `bgColor="primary"` → D9.

### D7 — Delete rather than migrate what F6 measured as dead

`PanelLink` (and `to`/`linkLabel`), `PanelShadow` (and `shadow`), `bgOverlay`,
`bgAlign`/`PanelBgAlignmentsEnum`, `PanelBody`'s `noMinHeight` and `noPadding`,
`PanelHeading`'s `hero`, and the unused members of the remaining enums.

`PanelShadow`'s three `shadow="top"` sites are a gradient scrim for text over a
background image — which `PanelHeading` already implements as `--top`/`--bottom`.
They move onto `PanelHeading shadow` and the component goes.

`title-align` and `multiline` were clearly _intended_ at their four sites each;
see Q3.

### D8 — Adopt MetricsCard's padding pair

`PanelHeading` `16px 18px 12px`, `PanelBody` `4px 18px 18px`. Per F7 this removes
the reason `noPaddingTop` exists at 12 sites, so that prop goes too.

### D9 — `bgColor` does not become `filled`; `StatsPanel` becomes tiles

The census undercounts this one badly. `bg-color="primary"` has **2** direct call
sites — but one is `visual-tests/panels.vue` and the other is `StatsPanel`, which
is rendered **69 times**:

```
hangar/stats 16   FleetStats 15   PublicFleetStats 14
stats 10          PublicHangarStats 9   admin/index 5
```

So the filled-primary surface is not a rare accent, it is the entire appearance
of the app's stat tile, laid out four-up in `col-lg-3` / `col-sm-6` grids. Sixteen
saturated `$primary` blocks on one page is the loudest thing in the UI, and it
reads as a leftover from a design the rest of the app has moved past. Carrying it
forward as a `filled` prop preserves the problem behind a new name.

The metrics-card language already answers this, and the shape is a match:
`metrics-card__hero--grid` **is** a stat-tile grid, and `metrics-card__tile`
emphasises one figure with a 3px `$primary` gradient rail against a
`$gray-black` fill rather than by flooding the surface.

```
StatsPanel  →  a metrics tile, not a filled panel
               $gray-black fill, 3px $primary rail
               Orbitron tabular value, uppercase tracked label
               grids of them collapse into one $hero container
```

This deletes an axis instead of renaming one: `filled` never enters the API,
`PanelBgColorsEnum` goes entirely (its `ADMIN` member was already dead per F6),
and the `bg-image` / `bg-rounded` pair is left as the only background concern
`Panel` carries.

Second-order benefit: those grids sit at `col-lg-3` (~345px) and `col-sm-6`
(~258px), so 69 of the app's narrowest panels are also the ones where F3's cap
collapse is worst. Both defects clear in the same component.

Cost, stated plainly: `StatsPanel`'s own markup and `index.scss` are rewritten
(40px value, `min-height: 83px`, icon column), and the `NumberFlow` value
animation has to survive the move to a tile. That is a real rewrite of one
component, against removing a surface variant from the base primitive.

**Status: the component half is done.** `StatsPanel` is a tile — `slim` frame,
`$primary` rail, Orbitron figure with tabular numerals — built on
`metricsCard.scss`'s own primitives rather than a copy, so the two stay in step.
`index.scss` is deleted. It is `--primary` at every instance deliberately: each
`StatsPanel` holds one figure in its own container, so it _is_ the headline one
there and the rail marks it rather than decorating it.

**The host grids stay as they are — decided in review.** This plan originally
proposed collapsing each row of four into one `Panel` with a shared
`__hero--grid`, for 1px dividers and one frame per group. Reviewed against the
per-stat framing and the per-stat framing won: a tile in its own slim frame reads
as a discrete figure, which is what a stats page is a list of, where a shared
hero implies the four are facets of one measurement. It also leaves the six host
pages untouched.

Consequence to accept: the `__hero` container's 1px dividers never appear here,
so `StatsPanel` uses the tile primitive without the hero that normally holds it.
That is the one place the two diverge, and it is deliberate.

### Prop API: before → after

| Current                             | Uses              | New                         | Note                                 |
| ----------------------------------- | ----------------- | --------------------------- | ------------------------------------ |
| `slim`                              | 23                | _(omit)_                    | new default (D5)                     |
| `fill-height`                       | 11                | `fill-height`               | kept; `calc()` coupling dropped (F5) |
| `alignment`                         | 8                 | `alignment`                 | kept                                 |
| `inset`                             | 7                 | `inset`                     | kept                                 |
| `variant="error\|success\|primary"` | 7                 | `tone="…"`                  | D6                                   |
| `transparency="more"`               | 6                 | `translucent`               | D6                                   |
| `bg-image` / `bg-rounded`           | 6                 | kept                        |                                      |
| `shadow="top"`                      | 3                 | `PanelHeading shadow="top"` | D7                                   |
| `bg-color="primary"`                | 2 _(69 rendered)_ | **removed**                 | D9 — `StatsPanel` becomes tiles      |
| `outer-spacing`                     | 2                 | `outer-spacing`             | **kept** — F5                        |
| `animated`                          | 2                 | `animated`                  | kept                                 |
| `highlight`                         | 2                 | `tone="highlight"`          | D6                                   |
| `to` + `link-label`                 | 0                 | **removed**                 | D7                                   |
| `bg-overlay`, `bg-align`            | 0                 | **removed**                 | D7                                   |
| `PanelBody no-min-height`           | 16                | **removed**                 | no-op (F6)                           |
| `PanelBody no-padding-top`          | 12                | **removed**                 | D8                                   |
| `PanelBody no-padding`              | 0                 | **removed**                 | D7                                   |
| `PanelHeading title-align`          | 4                 | dropped                     | Q3                                   |
| `PanelHeading multiline`            | 4                 | dropped                     | Q3                                   |
| `PanelHeading hero`                 | 0                 | **removed**                 | D7                                   |

Net on `Panel`: **15 props → 10**, and the most-passed prop (`slim`) disappears
from every call site.

## Phases

### Ordering note

As in `btn-redesign`, the prop API and the visuals are orthogonal — API in
`index.vue`/`types.ts`, look in the component's CSS — so the codemod can land
before the design is final. The two dependencies that _are_ ordered: D2 must land
before D3 (one box before one pair of caps), and Panel must be rebuilt before
MetricsCard can be folded into it.

### Phase 0 — De-risk gates

1. ~~**Surface `@apply` gate.**~~ **Done — passed.** Verified with a probe
   component built through this repo's own production pipeline
   (`NODE_ENV=production vite build`), then read back out of
   `public/vite/assets/`. Exit 0, no `Unknown at rule` warnings. Every construct
   the surface needs survived:

   ```css
   .probe[data-v-c852011b]{border-radius:var(--radius-surface,16px);
     border-color:var(--color-edge,#7a828880);
     background-color:var(--color-surface,#272b30e6);
     box-shadow:var(--shadow-surface,0 6px 18px -12px #000c);…}
   .probe[data-v-c852011b]:before{content:"";
     background-color:var(--color-endcap,#7a8288);
     left:max(10px, var(--cap-inset,12%));
     height:var(--cap-h,4px);
     border-radius:0 0 var(--cap-r,3px) var(--cap-r,3px);…}
   .probe--slim[data-v-c852011b]:before{content:none}
   ```

   Confirmed specifically: `@apply` works inside `::before`/`::after` rules;
   `max()` survives minification untouched; the split inward-edge radius
   survives; `content: none` survives; tone selectors compose.

   **The embed premise holds for surfaces too**, and by a mechanism worth
   recording. Theme utilities inline with literal fallbacks as `btn-redesign`
   found — but the compiled file _also_ carries its own copy of

   ```css
   @property --tw-border-style {
     syntax: "*";
     inherits: false;
     initial-value: solid;
   }
   ```

   which is what keeps `border-style:var(--tw-border-style)` valid where
   `tailwind.css` was never loaded. Without that inlined `@property`, an
   `@apply border` would compute to no border at all in the embed. The
   `embed-*.css` bundles do **not** define it; each component's own stylesheet
   does. So the remaining embed question is unchanged and still
   `btn-redesign`'s Phase 0 gate 2 — whether component scoped CSS reaches the
   embed bundle at runtime — not whether it would work once there.

   Note this makes the hand-written `var(--cap-h, 4px)` fallbacks load-bearing,
   not decorative: unlike the theme utilities, Tailwind adds no fallback to a
   bare `var()` in a hand-written declaration. `tailwind.css` carries a comment
   to that effect.

2. **Visual baseline — by eye, not by snapshot.** Extend
   `visual-tests/panels.vue` to the full variant × tone × state matrix
   (default/slim × 5 tones × translucent, animated, fill-height, alignment,
   inset, bg-image) plus a **narrow-width rig** at `col-md-4` and `col-sm-6` —
   F3's 45% and 38% cases. This is the human review surface for D5's intentional
   diffs; it is **not** automatable, see below.
3. **`Panels.spec.ts` — computed-style invariants against production routes.**

   The obvious plan — Playwright snapshots of `visual-tests/panels.vue` — does
   not work, and `btn-redesign` already paid to find out. Two reasons, both
   recorded in `Buttons.spec.ts`:

   - `frontend/pages/routes.ts` gates the visual-tests routes behind
     `process.env.NODE_ENV !== "production"`. The e2e run uses a production
     build, so a spec pointed at `/visual-tests/panels/` passes only against a
     dev server.
   - Pixel baselines are keyed per platform, so they would have to be built
     inside the e2e container.

   Follow the pattern that PR settled on instead: assert the named invariant
   with computed style against a real route, so a failure says _which_ invariant
   broke rather than that something moved.

   | Route     | Covers                                                                                                                                                           |
   | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | `/ships/` | the ship card — one frame not two, one pair of caps, proportional inset, `fill-height` equalisation, `.panel` class and `panel-heading-title` still present (F9) |
   | `/stats/` | `StatsPanel` as tiles, and the chart panels that lose the 286px floor (Q2)                                                                                       |

### Phase 1 — Tokens

4. ~~Extend `@theme` with D4's surface tokens; raise `--color-endcap`.~~
   **Done.** `entrypoints/tailwind.css` now carries `--color-surface`,
   `--radius-surface`, `--radius-surface-slim`, `--shadow-surface`,
   `--shadow-surface-slim` and `--color-edge-faint` in `@theme`, plus the cap
   geometry in a `:root` block below it — deliberately outside `@theme`, since
   those generate no utilities and `@theme` is for values Tailwind turns into
   classes.

   `--color-endcap` is now `#7a8288`. **This changes #4338's buttons**, which is
   intended (D3) but means the diff should be reviewed on
   `visual-tests/buttons.vue` as well as `panels.vue`.

### Phase 2 — Rebuild `Panel`

5. New `types.ts`: `PanelVariantsEnum` (default/slim/bare), new `PanelTonesEnum`,
   drop `PanelTransparenciesEnum`, `PanelBgAlignmentsEnum`, `PanelShadowsEnum`;
   de-duplicate the corner type.
6. New `index.vue`: single box (D2), `variant` × `tone` × `filled` (D6),
   `v-bind="$attrs"` preserved, `.panel` class retained (F9), `PanelLink` and
   `PanelShadow` deleted.
7. New component CSS in plain `<style scoped>` (D4), proportional caps (D3).

### Phase 3 — Sub-components

8. `PanelHeading`: padding pair (D8), `tone="metric"` for D1, real `titleAlign` /
   `multiline` or removal (Q3), `hero` dropped, `panel-heading-title` kept (F9).
9. `PanelBody`: padding pair (D8); `noMinHeight`, `noPaddingTop`, `noPadding`
   dropped; five `rounded-*` blocks collapsed to logical corner utilities.
10. `PanelImage`: unchanged apart from the corner-type de-duplication.

### Phase 4 — Fold in `MetricsCard`

11. ~~Rewrite `MetricsCard` as a `Panel` composition.~~ **Done.** The frame is
    Panel's; `metricsCard.scss` is untouched and the card hands its slot straight
    through, which `MetricsCard/index.spec.ts` now asserts. The slim head keeps
    its rule through two new `PanelHeading` options — `compact` and `divider` —
    rather than a `:deep()` reach into Panel's internals.
12. **Outstanding.** The 11 metrics-card sites are not yet verified in a browser,
    `Hardpoints/Group`'s `--slim` cards and `PowerDistribution`'s interactive
    tiles above all.

### Phase 4b — The card components

The most-viewed surfaces in the app, and all `Panel` consumers, so they change
whether or not they are touched. Each needs a deliberate pass rather than the
codemod:

- **`Models/Panel`** — the ship card. `bg-image` + `bg-rounded` kept;
  `shadow="top"` moves to `PanelHeading` (D7); gains `fill-height` (D5). Reached
  through `Vehicles/Panel`, which wraps it, and `Fleets/VehiclePanel`, which
  restyles `.panel-image` and `.panel-heading` from outside (F11).
- **`Modules/Panel`** — same shape, same three changes.
- **`Fleets/Logistics/InventoryPanel`** — the third `shadow="top"` site.
- **`embed/components/Models/Panel`** — the embed's own card, which restyles
  `.panel-inner` and `.panel-heading`; gated on the F8 embed reconciliation.

Verify at `col-lg-4`, `col-xl-3` and `col-3xl-2` — the ship grid's real widths,
and the ones where F3's cap collapse was worst.

### Phase 5 — Codemod the call sites

13. Script D6's mechanical mappings over the 91 direct sites; hand-edit the
    wrapper components (`BaseTable`, `Box`, `AppModal/Inner`, `TeaserPanel`),
    which is where the 116 indirect instances are configured.
14. Rewrite `StatsPanel` as a metrics tile per D9, and collapse its six host
    grids into `__hero--grid` containers. This is the largest single edit in the
    plan and the one with the most visible blast radius — 69 instances.
15. `prettier --write` then `eslint` on touched files.

### Phase 6 — Un-leak the six files — **mostly nothing to do**

17. ~~Fold F11's overrides into variants or scoped exceptions.~~ **Done.** Per the
    corrected F11 there was one file to act on and it was dead:
    `VehiclePanel/index.scss` is deleted. The two preview pages style their own
    hand-rolled divs and need no change.
18. **Nothing to reconcile — the gate is answered, and it moves the duplicate
    out of scope rather than into it.** Walking the built manifest from
    `entrypoints/embed.ts` gives 14 chunks pulling four CSS files, all of them
    component CSS: `Collapsed`, `Loader`, `Slider`, `pages`. `Collapsed-*.css`
    carries two `data-v-` selectors, its own `@property --tw-border-style` and 46
    inline `var(--token, literal)` fallbacks — so component scoped CSS _does_
    reach the embed at runtime, self-sufficient, even though `embed.js.erb` links
    one stylesheet and fetches only `:scripts`. Vite injects async-chunk CSS
    itself; `Router-*.js` references `pages-*.css`.

    What that changes: the 259-line duplicate is **not** required by a
    CSS-delivery limitation. It exists because the embed has a parallel
    _component_ — `embed/components/Models/List` imports
    `@/embed/components/Models/Panel`, never the shared one — so there is no
    shared Panel in the embed's module graph to deliver CSS for. Collapsing it
    means replacing that component, not moving stylesheet rules, which is a
    larger and separate piece of work.

    Done here after all, and it turned out to be a deletion rather than a
    rewrite: every rule in the 259-line file was reachable only from that one
    component, and the classes it also defined for a highlight tone, panel
    boxes, images, footers, details, transparency levels and tables had no user
    at all. The embed card composes `Panel` and `PanelHeading`, the file is
    gone, and the production-status band moved into the component with the
    frontend card's treatment.

    The specificity point is what settles the "could they coexist" question:
    `embed.scss` wraps every partial in `#fleetyards-view`, so those rules
    outranked the component's own scoped styles. Keeping the duplicate while
    adopting the shared component was never possible.

    Confirmed on `/embed-test` and `/embed-v2-test` — one box at radius 16 with a
    2px edge, caps at 4px `#7a8288` with a 3px inward radius and a 12% inset from
    the hand-written fallbacks alone, the 286px image floor intact, no legacy
    wrapper in the DOM.

### Phase 7 — Verify

19. Playwright snapshots green; review the intentional diffs (D5's min-height
    removal above all).
20. `pnpm test`, `pnpm test:e2e:run`, embed page checked in a browser on a light
    and a dark host page.
21. `knip` for newly-dead exports (`PanelLink`, `PanelShadow`, dropped enums).

## Open questions

- ~~**Q0** Which cap values?~~ Settled in review: `4px`, `max(10px, 12%)`,
  `#7a8288`, inward radius `3px`, no fade. What remains is that
  `--color-endcap` is shared with #4338, so the colour change restyles every
  button in the app and lands in that PR's review too — only cheap while it is
  open.
- **Q1** — `--color-control` is byte-identical to `$panel-bg` (F10), so a solid
  button on a panel reads only by its edge and caps. Intended, or should one of
  the two step apart? Cheapest to settle while `btn-redesign` is still open.
- ~~**Q2** Chart heights.~~ Neither: the premise was wrong. `Chart` already
  declares `height?: number` defaulting to `400` and hands it to the chart
  instance, so the 286px floor was never what held those panels open. Measured
  on `/stats/`: every chart panel is 494px (400 + heading and padding), and the
  only non-chart panels there are the `stats-panel` tiles at 102px, which is
  their intended height. No edits.
- ~~**Q3** `title-align` / `multiline`.~~ Deleted. No component has ever
  declared either prop, so they were not merely ignored - they fell through
  Vue's attribute inheritance and rendered into the DOM as stray attributes on
  the heading element. Removing them changes nothing on screen. A right-aligned
  wrapping title in those four modals is a feature to add deliberately, not a
  regression to restore.
- ~~**Q4** `bare` vs `translucent`.~~ Nothing to collapse - `bare` was dead on
  arrival and is deleted. It had no call site, and the prop it stood in for had
  none either: main offered three transparency levels and only `more` was ever
  used, at the six preview panels that now pass `translucent`. `complete`, which
  `bare` absorbed, was never asked for by anything. The only `<Panel>` tags
  carrying `variant` or `translucent` are `hangar/preview`, `fleets/preview`,
  `StatsPanel` and `MetricsCard`.
- ~~**Q8** Does the table interior come along?~~ No - out of scope, filed as
  [#4369](https://github.com/fleetyards/fleetyards/issues/4369). The frame still changes for free at 36 sites and the row hover rail's
  triple `$primary` glow and solid `$gray` header rule still out-shout it; that
  mismatch is this PR's to own and to hand on, not to absorb as a third
  component rewrite.
- ~~**Q9** Delete or finish `BaseTable2`?~~ Neither - left alone. Worth
  recording why the "should not quietly acquire the new frame" caveat needs no
  action: `Table2` composes `Panel` and `PanelHeading` rather than copying their
  styles, so it tracks the rebuild automatically and correctly. It is still only
  reachable from the visual-tests page, so nothing presents it as shipped.

  **Overturned later: deleted.** That answer was about it needing no work, which
  was true, and not about it being worth keeping. 540 lines reachable only from a
  demo page kept producing findings that had to be ruled out of scope by hand --
  #4596 had to exclude its copy of the row-rail bloom explicitly. Deleting it
  removed the last bloom in the codebase as a side effect.

- ~~**Q5** Which spacing wins?~~ The panel's. Both the card and its slim
  variant now use `margin: 0 0 21px`; a column of cards used to sit almost twice
  as far apart as a column of panels, visible on the ship page where the two
  stack in one sidebar.

## Design review

Old and new specimens side by side at the widths the census measures, an
interactive width rig for the end-cap inset, the variant × tone matrix, and
panels rendered with `feat/btn-redesign`'s buttons and the metrics panes:
<https://claude.ai/code/artifact/d550dae9-6f59-4b7f-942c-adc5b3071847>
