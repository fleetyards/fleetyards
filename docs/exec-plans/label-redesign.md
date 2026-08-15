# Filter label redesign

## Goal

Rebuild the filter labels — the group pills on the hangar page and the
classification pills beside them — on the control language established by
[`btn-redesign.md`](btn-redesign.md) and [`panel-redesign.md`](panel-redesign.md),
as **one** primitive shared by both consumers instead of a global stylesheet that
two components reach into from opposite directions.

Branch stacks on `feat/panel-redesign`; sibling of `feat/footer-redesign`. The two
touch disjoint files and can merge in either order.

## Context

The pills are the last interactive surface in the app still on the pre-redesign
frame. Measured surface:

| Metric | Count |
| --- | --- |
| Components rendering `.label` | 2 (`Hangar/GroupLabels`, `Models/ClassLabels`) |
| Call sites | 4 — hangar (both), public hangar (groups), `Fleets/ShipsList` (classes) |
| Stylesheets involved | 2 (`partials/labels.scss` 133 lines, `GroupLabels/index.scss` 14) |
| `!important` declarations overriding `Btn` | 6 |
| Playwright / Vitest specs coupled to the markup | **0** |
| Distinct pill primitives in the app | 3 (`base/Pill`, `.pill` partial, `.label`) |

Both label rows render **side by side in one flex row** on the hangar page
(`pages/hangar/index.vue:302` and `:308`, inside `.hangar-labels`). That is why
the scope is the shared primitive and not the group pills alone: restyling one
leaves a row of old-language pills immediately beside a row of new ones.

## Findings that drive the design

### F1 — Three pill primitives, and the interactive one is the odd one out

| | `base/Pill` | `.pill` partial | `.label` |
| --- | --- | --- | --- |
| Fill | `rgba($primary, .2)` | solid `$primary` | `$panel-bg` |
| Edge | `1px rgba($primary, .4)` | none | `2px $panel-inner-border` |
| Radius | 4px | `$border-radius-base` (4px) | 6px outer / 4px inner |
| Interactive | no | no | **yes** — filter toggle |
| End-caps | no | no | **yes** — 2 hairlines, `#444` |

`base/Pill` already anticipates the token language (a tinted fill inside a
matching edge at low alpha, per-variant). `.label` is the only one carrying the
retired frame, and it is the only one users click.

### F2 — `.label` is the retired double frame, in miniature

`labels.scss` builds, on a ~26px-tall element:

```scss
background-color: $panel-bg;                    // fine — is --color-surface
border: 2px solid $panel-inner-border;          // rgba(#c8c8c8, .9) — the glare
border-radius: 6px;                             // outer box
&::before, &::after { background-color: #444; } // the pre-d04ff408a cap colour
.label-inner { border-radius: $border-radius-base; } // second, inner box
```

Every value the Panel plan's F1/F2 tables list as dated is here: the
`rgba(#c8c8c8, .9)` edge that `d04ff408a` replaced with `--color-edge`, the `#444`
cap that the same commit moved to `--color-endcap: #7a8288`, and an outer box
wrapping an inner box for a single surface.

### F3 — Fixed 10px cap insets, at the scale where they fail hardest

Same defect as the Panel plan's F3 (`right: 10px; left: 10px`), except a pill's
width is content-driven, so the failure is routine rather than layout-dependent:

| Pill content | Approx. width | Cap (W − 20) | Share |
| --- | --- | --- | --- |
| `Exploration: 12` | 130px | 110px | 85% |
| `Solo: 3` | 70px | 50px | 71% |
| `A: 1` | 44px | 24px | 55% |
| the `+` add-group button | **~30px** | **10px** | **33%** |

Group names are user-supplied, so the short end is not hypothetical — and the
`+` button next to the row is a fixed, always-present instance of the worst case.

### F4 — The states are hand-mixed colours, not tokens

```scss
&:hover, &.active { color: invert($text-color); background: $panel-inner-border; }
&.inverted        { background: darkred; }
```

`invert(#c8c8c8)` is `#373737` — dark text on a near-white fill, which is louder
than any other control in the app and reads as a different design system.
`darkred` (`#8b0000`) is a CSS keyword, not `--color-danger` (`#dc3545`). There is
no press state, and hover and active are the same declaration, so an active pill
gives no hover feedback.

### F5 — The mobile path is a `!important` leak into `Btn`

`labels.scss:87-133` styles `.labels-dropdown-item` by reaching at `Btn`'s
internals through `> :first-child` with six `!important`s. This is exactly the
class of override `a6a368433` ("un-leak the panel-btn overrides from 17
stylesheets") removed — `labels.scss` survived that sweep only because its
selectors never contained `panel-btn`.

`Btn` already ships an `active` prop (used by the locale dropdown in
`frontend/App.vue`). The dropdown items pass `class="active"` instead and then
fight the component's own styling.

### F6 — Two components, one language, gratuitously divergent

| | `GroupLabels` | `ClassLabels` |
| --- | --- | --- |
| States | tri-state: neutral / in / **not-in** | binary |
| Filter transport | `useHangarFilters` composable | `route.query` mutated by hand |
| Row title | `<h3 class="label-title">` | none |
| Colour dot | yes, inline `background-color` | no |
| Count | `{{ name }}: {{ count }}` | `{{ label }}: {{ count }}` |
| Reorder | Sortable + sort mutation | no |
| Enter/leave | none (see F10) | `<transition-group>` |
| Edit | right-click → modal | no |
| Mobile dropdown label | `t("labels.groups")` | **hardcoded `"Classifications"`** |

The count formatting, the row, the dropdown fallback and the chip itself are the
same thing written twice.

### F7 — Dead and undeclared props

- `GroupLabels` is passed `:label="t('labels.groups')"` at all three call sites
  and **declares no `label` prop** — it falls through onto the root element as a
  DOM attribute while the component renders its own hardcoded
  `t("labels.groups")` title.
- `ClassLabels` **declares** `label` and never renders it; its dropdown shows the
  untranslated literal from F6 instead.

So the one string both call sites deliberately pass is discarded by both
components. Same failure as the footer plan's F4 — an unrelated component,
identical mechanism.

### F8 — The pills are anchors pretending to be toggles

```html
<a class="label label-link" @click.exact="filterGroup(group.slug)"
   @click.right.prevent="openGroupModal(group)">
```

No `href`, no `role`, no `tabindex` — so the filters are unreachable by keyboard
and invisible to assistive tech, and `.label` even sets `cursor: default` which
`.label-link` then has to undo. The tri-state is signalled by colour alone
(WCAG 1.4.1) with no legend, so "excluded" is indistinguishable from "styled
red" unless you already know the interaction. Right-click is the **only** way to
edit a group, and nothing announces it.

### F9 — The styling is split across two files that overlap

`partials/labels.scss` sets `.labels { margin-bottom: 20px }` and `.label-title
{ display: inline-block; margin-right: 10px }`; `GroupLabels/index.scss` then
re-declares `.labels` as the flex row and `.label-title` with a `margin-top`.
Global partial and scoped component stylesheet each own part of one layout.

### F10 — A 500ms `transition: all` on every pill

Both components put `.fade-list-item` on the pills, which is
`transition: all 0.5s` (`shared/transitions.scss:81`) — the same 500ms the Panel
plan replaced with `150ms ease` for being perceptibly broken. On `GroupLabels`
the class is applied **outside any `<transition-group>`**, so it contributes no
enter/leave animation at all; it only slows every hover and fights Sortable's own
`animation: 150` during a drag.

### F11 — No test coupling, and tokens are available

No Playwright spec or Vitest test references `.label*`, either component, or the
hangar label row. `labels.scss` is imported only by `frontend/partials.scss`, and
`application.html.erb` loads `tailwind.css`, so `:root` and every `@theme` token
are registered. Unlike the Panel plan's F8 there is no embed constraint — neither
component renders in the embed bundles.

This is a free hand: the redesign can change the markup outright.

## Decisions

### D1 — One primitive: `base/Chip` and `base/Chip/Row`

```
base/Chip/index.vue        the toggle itself — <button>, states, dot, count
base/Chip/Row/index.vue    the row — title, wrap, gap, mobile dropdown fallback
```

Both `GroupLabels` and `ClassLabels` become thin, behavioural wrappers: they own
their filter transport (F6), their data shape and their extras (Sortable, edit),
and own no styling at all.

Named `Chip`, not `Label`, for two reasons: `label` is taken by form labels
throughout `FormInput`, and a distinct name gives the eventual fold-in of
`base/Pill` and the `.pill` partial an obvious target. That fold-in is **out of
scope here** (see Open questions) — this plan does not touch either.

### D2 — One box, one border, and no end-caps

```
background:    var(--color-control)        /* rgb(39 43 48 / .9) */
border:        1px solid var(--color-edge-soft)
border-radius: var(--radius-control-bare)  /* 6px */
transition:    150ms ease
hover:         var(--color-control-hover)
active/press:  var(--color-control-press)
```

The inner box goes; `.label-inner` is deleted rather than restyled.

**No caps on a chip.** That is the same call `Panel` already makes for
`--slim` — "a grid of repeated cards is exactly where a cap this loud turns to
noise" — and a wrapping row of 12 pills is a denser repetition than any card
grid. This resolves F3 by removing the motif at this scale rather than
re-deriving its geometry, and it keeps the cap meaningful as the signature of a
*surface*: panel, band, dropdown — not every clickable thing.

### D3 — States on tokens, tinted like `base/Pill`

| State | Fill | Edge | Text |
| --- | --- | --- | --- |
| neutral | `--color-control` | `--color-edge-soft` | `--color-text` |
| included | `rgb(66 139 202 / .22)` | `rgb(66 139 202 / .5)` | `--color-text` |
| excluded | `rgb(220 53 69 / .22)` | `rgb(220 53 69 / .5)` | `--color-text` |

The alphas are `base/Pill`'s (`.2`/`.4`), nudged one step for the darker
`--color-control` ground beneath them. Text stays `--color-text` in all three
states — the `invert($text-color)` flip of F4 goes, so a selected pill reads as
*tinted*, not inverted, and hover remains distinguishable from selected.

### D4 — The exclude state gets a non-colour affordance

A leading icon carries the state — `fa-check` for included, `fa-minus` for
excluded, nothing for neutral — reserving colour as reinforcement (F8, WCAG
1.4.1). The icon slot is where `GroupLabels`' colour dot already sits, so
included/excluded replace the dot rather than crowding it, and the tri-state
becomes legible without a legend.

`ClassLabels` is binary and simply never reaches the third state; `Chip` takes
`state: "neutral" | "included" | "excluded"`, not two booleans.

### D5 — `<button type="button">`, with real focus

`aria-pressed` for the binary consumer, `aria-checked`-style semantics for the
tri-state, `focus-visible` ring on `--color-primary`, keyboard activation for
free. Group editing gains a real affordance (a small edit icon on the chip, shown
when `editable`), with right-click kept as an unadvertised accelerator rather
than the only route (F8).

### D6 — The group colour becomes a custom property

`:style="{ '--chip-dot': group.color }"` on the chip root, with the dot drawn by
the component. Removes the nested inline-styled span and the `!important` width
override the dropdown copy needs (F5).

### D7 — Mobile goes through `Btn`'s API, not around it

`Chip/Row` keeps the `BtnDropdown` fallback but drives the items with `Btn`'s own
`active` prop and slots. Anything genuinely missing — a tri-state tone on a menu
item — is added *to* `Btn`, since that is the component that owns control
surfaces now. `.labels-dropdown-item` and its six `!important`s are deleted, not
ported.

### D8 — Both stylesheets are deleted

`partials/labels.scss` is removed from `frontend/partials.scss` and deleted;
`GroupLabels/index.scss` goes with it (F9). Styling lives in `Chip` and
`Chip/Row` as scoped `<style>` with `@reference "…/tailwind.css"`, matching
`Panel` and `Btn`.

### D9 — The `label` prop starts working

`Chip/Row` takes `label` and renders it as the row title on desktop and as the
dropdown label on mobile. `GroupLabels` declares it and drops its hardcoded
`t("labels.groups")`; `ClassLabels` forwards the one it already declares, which
removes the untranslated `"Classifications"` (F7).

### D10 — Motion at 150ms

`.fade-list-item` comes off the pills. `ClassLabels` keeps its
`<transition-group>` for list enter/leave but on a short transition; `GroupLabels`
never had a working one and does not gain one, which also stops the 500ms
`transition: all` fighting Sortable (F10).

### Prop API: before → after

```
GroupLabels   hangarGroups, hangarGroupCounts, editable
              + label (declared, F7)                        @highlight unchanged
ClassLabels   countData, filterKey, label                   label now rendered

Chip          state, dot?, count?, icon?, disabled?          @toggle
Chip/Row      label?, sortable?                              (slot: chips)
```

## Phases

### Phase 0 — Baseline

Screenshot the four call sites, desktop and mobile: hangar (both rows side by
side), public hangar, `Fleets/ShipsList`, and both mobile dropdowns. Capture the
tri-state on a group pill and the `+` button — the F3 worst case — since those
are the comparisons that decide whether D2's cap removal reads as intended.

F11 means there is no test gate to satisfy first.

### Phase 1 — Build `Chip` and `Chip/Row`

Component, scoped styles, `types.ts` with the state enum (matching
`Panel/types.ts`' `PanelTonesEnum` convention), and a `visual-tests` section —
`pages/visual-tests/` has a page per primitive, so this gets one: all three
states × dot / no dot / count / icon, a wrapping row, and the narrow `+` case.

### Phase 2 — Migrate `GroupLabels`

Chips + `Chip/Row`, Sortable re-pointed at the row's container (drop
`display: contents`, which leaves the sortable container with no box), edit
affordance, declared `label`.

### Phase 3 — Migrate `ClassLabels`

Chips + `Chip/Row`, binary state, `label` rendered, hardcoded string gone.

### Phase 4 — Delete the old styling

`partials/labels.scss`, `GroupLabels/index.scss`, and the `@import` in
`frontend/partials.scss`. Grep for `label-inner`, `label-color`, `label-title`,
`labels-sortable`, `labels-dropdown` to confirm nothing outside the two migrated
components referenced them.

### Phase 5 — Verify

`pnpm test`, `pnpm lint:fix`, `pnpm lint:ts`, the Playwright suite, and the
Phase 0 screenshots re-shot. Add a Playwright spec for the tri-state filter
round-trip on the hangar page — F11 found none, and the tri-state is the one
behaviour here that a screenshot cannot confirm.

## Implementation notes

Where the built thing differs from the plan above, and why.

### `Chip` gained a `bare` prop

Not foreseen: the mobile fallback renders its items as `Btn`s (D7), and a
`<button>` may not be nested inside a `<button>`. `bare` renders the chip's
*contents* — dot, state icon, label, count — with no frame and no button, so a
menu item reuses the chip's metrics instead of re-implementing them, which is
what would have brought F5's duplication back in a new form.

It also delivers, early, the non-interactive variant D1 reserved for a later
`base/Pill` fold-in.

### No `icon` prop

D4's icon is derived from `state` rather than passed, so a caller cannot desync
the two. The prop list in D1's table loses `icon`, gains `bare` and `editLabel`.

### The row title needed a string that did not exist

D9 renders `label` as the desktop row title, and the two `ClassLabels` call sites
were passing `t('labels.hangar')` and `t('labels.fleet.classes')` — "Hangar" and
"Fleet". Those are *scope* names, fine as a mobile dropdown trigger and wrong as
a title over a row of classification chips.

Both now pass a new `labels.classifications` key. That is also what the mobile
dropdown hardcoded in English (F7), so mobile keeps its wording and gains its
translation, and the desktop title reads correctly.

### `ClassLabels` chips are disabled without a `filterKey`

The prop is optional and `filter()` already returned early without it, while the
old markup only dropped `.label-link` and changed the cursor. A chip that looks
live and does nothing is worse than a dimmed one. No call site is affected —
both pass `classificationIn`.

### Verification

`pnpm test` (148), `pnpm lint:fix`, `pnpm lint:ts` and a `bin/vite build` all
pass.

Phase 5's Playwright spec landed as `test/playwright/e2e/Chips.spec.ts` with a
`chips` scenario, and **CI ran it: six of the seven cases passed first time.**

It could not be run locally — the local harness does not boot the SPA at all, so
every spec, new or old, sees only the server-rendered heading and times out. The
untouched `Footer.spec.ts`, whose whole body is

```ts
await page.goto("/");
await expect(page.getByTestId("app-footer")).toBeVisible();
```

fails the same way, as does `Hangar.spec.ts › Shows Preview`. Anything e2e on
this stack needs CI to be believed.

### What the seventh case found

The `excluded`-state assertion failed with `"Combat2included"` — two clicks left
the chip *included*. Not a component defect: the tri-state lives in the query
string and `useFilters` **debounces** that write, so a second click landing
before the first has applied reads the same pre-update `filters.value` and sets
`included` again rather than advancing.

The fix is an intermediate assertion between the clicks, which is why the
`cycles` case passed while this one did not — it was already waiting on each
state. Worth knowing beyond the test: the row cannot be driven faster than the
debounce, and a user double-clicking a chip gets one transition, not two. That is
`useFilters` behaviour shared by every filter in the app, so it is recorded here
rather than changed.

The scenario targets the *public* hangar rather than the signed-in one for this
reason: it removes the login step the other authenticated specs spend a minute
on, and the public page renders the same `GroupLabels` with the same tri-state
filter. Cross-row coverage (groups beside classifications) is the one thing that
costs — that pairing only exists behind a session.

## Open questions

1. **Fold `base/Pill` and the `.pill` partial into `Chip`?** Deliberately
   deferred: it reaches call sites well beyond the hangar (ship pages, API docs)
   and would double this PR. `Chip` is designed so they can collapse into it as
   a non-interactive variant later.
2. **Does the excluded state need a legend as well as D4's icon?** A first-time
   user still has to discover that a third click means "exclude". A tooltip on
   the chip stating the next state is cheap; whether that is enough is a call to
   make against the built thing in Phase 1.
3. **Should `ClassLabels` move to `useHangarFilters`-style filtering?** Its
   hand-rolled `route.query` mutation (F6) is a latent bug source, but it is
   behaviour, not design language, and it also serves the fleet page. Out of
   scope unless Phase 3 trips over it.

## Follow-up: classification exclusion

Closes F6's first row and open question 3, both of which turned out to be one
question. Asked for directly: "can we also exclude classifications like we can
with the groups filter?"

### It was never a frontend gap

`Chip` has carried the excluded state since Phase 1 and `ClassLabels` simply
never reached it. The reason is upstream of the component: `hangarGroupsNotIn`
exists as an API query key and `classificationNotIn` did not exist anywhere -
not in `HangarQuery`, not in `FleetVehicleQuery`, not in any permit list. The
tri-state is a schema feature that a chip happens to render.

Ransack needed nothing: `ransack_alias :classification, :model_classification`
composes with the built-in `not_in` predicate, so declaring the key in the two
query schemas is the whole filter. The hangar permits it automatically -
`HangarFiltersConcern` derives its permit list from the generated schema through
`ParamsHelper` - while the fleet's hand-written list needed the key adding.

### The counts had to go blind first

Exclusion is unusable while a chip's count is computed from the set that chip is
filtering, and the two endpoints failed differently:

| | before | on excluding `combat` |
| --- | --- | --- |
| hangar stats | counts from the filtered `models` | `Combat 0` - nothing to aim at |
| fleet stats | the chip *list* is `models.map(&:classification).uniq` | the chip **disappears** |

Both now count against a scope ransacked without `classification_in` /
`classification_not_in`, which is what `group_count_vehicle_ids` has always done
for the group row. This is a visible behaviour change for plain inclusion too:
including `combat` no longer zeroes every other classification's count.

### Open question 3, answered

`ClassLabels` moved to `useFilters`. Not for its own sake - the hand-rolled
`route.query` mutation had no third state to write to and adding one by hand
would have been a second copy of the group row's cycle. The move also settles two
divergences F6 listed as gratuitous: empty keys now drop out of the URL and the
page resets on filter, so a classification click and a group click leave the same
query string.

Consequence worth knowing: the debounce documented above ("the row cannot be
driven faster than the debounce") now applies to the classification row too.

`excludeFilterKey` is a separate prop rather than derived from `filterKey`,
so a consumer whose endpoint has no `notIn` counterpart keeps the binary chip
instead of silently emitting a key the API would reject under
`additionalProperties: false`.
