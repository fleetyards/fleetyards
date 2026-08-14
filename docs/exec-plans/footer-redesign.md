# App footer redesign

## Goal

Bring `shared/components/AppFooter` onto the surface language of
[`panel-redesign.md`](panel-redesign.md) and [`btn-redesign.md`](btn-redesign.md):
one band, one border, one pair of proportional end-caps, a real layout instead of
five absolute positions — and fix the shared component's wiring to the three apps
that render it while the file is open anyway.

Branch stacks on `feat/panel-redesign`; sibling of `feat/label-redesign`. The two
touch disjoint files and can merge in either order.

## Context

The footer renders in **three** apps, from one shared component:

| App | Call site | Passes props | Renders links slot |
| --- | --- | --- | --- |
| frontend | `frontend/App.vue:275` | yes | yes — 4 links + locale dropdown |
| admin | `admin/App.vue:207` | yes | no |
| docs | `docs/App.vue:110` | yes | no |

| Metric | Count |
| --- | --- |
| Chrome-only DOM elements in the frame | 5 |
| Absolutely-positioned regions | 5 |
| Props passed by call sites | 4 |
| Props **declared** by the component | **0** |
| Frontend-only imports in this shared component | 2 |
| Test coupling | 1 Playwright (`data-test`), 1 Vitest (anchor count) |

## Findings that drive the design

### F1 — The footer is the last surface on the retired frame

| | `AppFooter` | Post-redesign language |
| --- | --- | --- |
| Fill | `rgba($gray-darker, .7)` | `--color-surface` — `rgb(39 43 48 / .9)` |
| Border | 3px `$panel-inner-border` | 1–2px `--color-edge` |
| Edge colour | `rgba(#c8c8c8, .9)` | `rgb(122 130 136 / .5)` |
| Cap colour | `#444` | `--color-endcap` — `#7a8288` |
| Cap geometry | fixed 80px / 40px | `max(10px, 12%)` |
| Muted text | `darken($text-color, 20/40%)` | `--color-muted`, `--color-gray-light` |

`$panel-inner-border` and `#444` are precisely the two values `d04ff408a`
retired; the footer sits directly below panels that no longer use either.

### F2 — The border stack is a hand-rolled end-cap, with the geometry inverted

Five elements exist purely to draw the top edge:

```html
<div class="app-footer__border app-footer__border-top">
  <div class="app-footer__border-left" />   <!-- 80px, 2px $panel-outer-border -->
  <div class="app-footer__border-right" />  <!-- 80px -->
</div>
<div class="app-footer__inner__border app-footer__inner__border-top">
  <div class="app-footer__inner__border-bg" /> <!-- full width − 40px, #444 -->
</div>
```

This is the Panel plan's F2 and F3 at page scale — and the fixed inset fails in
the *opposite* direction from a narrow panel. The outer pair is the only outer
border there is: two 80px ticks at the ends of a band as wide as the viewport.

| Viewport | Tick as share of width |
| --- | --- |
| 992px | 8% |
| 1920px | 4% |
| 2560px | **3%** |

The design intent — a motif holding a constant share of the edge — is what
`--cap-inset: 12%` encodes. At 3% it reads as a rendering artefact.

### F3 — Five absolute positions instead of a layout

`__social-links`, `__community-logo`, `__version` and `__sc-data-version` are all
`position: absolute` at the four corners, over a `text-align: center` block flow
carrying the links, support button and disclaimer. Nothing relates the two
groups, so the centred disclaimer has no reserved space and can run under the
corner regions between the desktop breakpoint and the width at which the
disclaimer's fixed `<br>` line breaks happen to fit.

The entire `max-width: $desktop-breakpoint` block then exists to undo four of the
five positions, plus a second `max-width: 370px` block for the nav offset.

### F4 — Every call site passes props the component does not declare

All three apps pass `:codename`, `:git-revision`, `:online` and a version — and
`AppFooter` declares **no props at all**, reading `useAppStore()` instead. The
bound values land on the root `<footer>` as fallthrough DOM attributes.

Admin and docs additionally pass `:revision`, which is not even the store's key
(`version`). The intent at the call sites is unambiguous and has never been wired
up.

### F5 — A shared component wired to one specific app

```ts
import { useAppStore } from "@/frontend/stores/app";
import ... "@/frontend/components/SupportBtn/Modal/index.vue"
```

`admin/stores/app.ts` and `docs/stores/app.ts` both exist, and admin and docs pass
their own store's values (F4) — which are discarded. The admin and docs footers
therefore render the **frontend** store, and instantiate a second app's store to
do it. Version and codename happen to agree because all three read the same
`window.APP_VERSION` / `window.APP_CODENAME` globals; `online` does not — it is a
frontend websocket concern the other two apps never update, so it is hardcoded
`true` for them.

The support modal is the same coupling: admin and docs ship a lazy import of a
frontend component and the `comlink` modal bus to render it.

### F6 — Magic numbers duplicated from elsewhere

```scss
.nav-visible .app-footer { right: 300px; }              // nav width, copy 5
@media (max-width: 370px) { .nav-visible .app-footer { right: 250px; } }
```

`300px` appears four more times in `partials/app-navigation.scss`. The footer
slides by a number it has no way to stay in sync with.

### F7 — `new Date().getFullYear()` in the template

`AppFooter/index.vue:99` calls it inline, so it is re-evaluated on every render
and is unreachable from a test that wants to freeze the year.

### F8 — The links slot is presentational markup at the call site

`frontend/App.vue` hand-types `|` between the four links. Admin and docs pass
nothing, so their `&__links` renders an empty `<div>` that still occupies its
`margin-bottom: 10px`.

### F9 — Tokens are available in all three bundles

`vite_stylesheet_tag 'tailwind.css'` is in `layouts/application.html.erb`,
`layouts/admin/application.html.erb` and `layouts/docs.html.erb`. `AppFooter`
never renders in the embed bundles, which are the ones that skip it — so unlike
the Panel plan's F8 there is no `:root`-not-registered case here. The
`var(--name, literal)` fallback convention is still followed, for consistency
with `Panel` and `Btn` rather than out of necessity.

### F10 — Test coupling is small but sharp

- `test/playwright/e2e/Footer.spec.ts` asserts `getByTestId("app-footer")` is
  visible. `data-test="app-footer"` is contract; keep it.
- `AppFooter/index.test.ts` asserts `findAll("a")).toHaveLength(4)` — a bare count
  of anchors, which the four social icons currently satisfy. Any change to the
  anchor set breaks it, and it would pass just as happily with four *wrong*
  anchors.

### F11 — Accessibility defects worth taking while here

- `aria-label="Discrod"` on the Discord link.
- The git revision is a `<span class="hidden">` under `display: none`, so the
  value is hidden from assistive tech too and reachable only through a hover
  tooltip on a `cursor: pointer` span that is not focusable or activatable.
- `opacity: .5` on the revision as the sole indicator of offline status.

## Decisions

### D1 — One band, one border, one pair of caps

All five chrome elements from F2 are deleted. The band becomes:

```
background:    var(--color-surface)
border-top:    2px solid var(--color-edge)
```

with a single top end-cap pair drawn the way `Panel` draws it — the same
`::before` mechanism, the same tokens:

```
left/right: max(10px, var(--cap-inset, 12%));
height:     var(--cap-h, 4px);
background: var(--color-endcap);
border-radius: 0 0 var(--cap-r, 3px) var(--cap-r, 3px);
```

Top edge only: the footer's bottom is the end of the document, so there is no
edge there for a cap to signature. Five divs become zero, and the motif matches
every panel above it at any viewport width (F2).

### D2 — CSS grid, replacing the five absolute positions

```
┌──────────────┬────────────────────────────┬──────────────┐
│ community    │  links                     │  social      │
│ logo         │  support                   │  links       │
│              │  disclaimer                │              │
├──────────────┴────────────────────────────┴──────────────┤
│ version                                    sc-data-version│
└───────────────────────────────────────────────────────────┘
```

Three columns over an explicit bottom row. Below `$desktop-breakpoint` the grid
collapses to one column in source order — which is what the existing media block
is laboriously reconstructing by resetting `position` four times (F3). The
disclaimer gets a real column, so it can no longer collide with the corners, and
its hardcoded `<br>` breaks can go with it.

### D3 — Declare the props; drop the store

`codename`, `version`, `gitRevision`, `online` become declared props. Every call
site already passes them (F4), so this is wiring up existing intent, not new API.
`@/frontend/stores/app` comes out, which is half of F5: each app then supplies its
own store's values, and `online` stops being a frontend concept silently applied
to admin and docs.

`admin/App.vue` and `docs/App.vue` change `:revision` to `:version`.

`window.COPYRIGHT_OWNER` and `window.SC_DATA_VERSION` stay as they are — globals
set by the layout for all three apps, not app-specific state.

### D4 — The support button moves to the slot

The other half of F5. `AppFooter` gains a named `actions` slot; `frontend/App.vue`
puts its `SupportBtn` there, keeping the frontend modal and the `comlink`
dependency in the frontend. Admin and docs pass nothing and render no support
button — which is the correct outcome regardless: neither has a support page.

### D5 — Tokens for the greys and the muted text

`darken($text-color, 20%)` → `--color-muted`; `darken($text-color, 40%)` →
`--color-gray-light`. `#444` → `--color-endcap`. `$panel-outer-border` and
`$panel-inner-border` leave the file entirely (F1).

### D6 — The nav offset stops being a copied number

A single `--nav-width` custom property, consumed by the footer's translate. Whether
`partials/app-navigation.scss` adopts it in the same PR is a judgement call at
implementation time — the footer must stop *duplicating* the number (F6);
converting the nav's own four occurrences is optional and easily split out.

Also: the offset is animated as `left`/`right`, which lays out on every frame. A
`translate3d` moves it to the compositor for free while the property is being
touched anyway.

### D7 — `getFullYear` becomes a computed

One line, and it makes the copyright year assertable (F7).

### D8 — The links slot lays itself out

`gap` on the slot container, and the `|` characters come out of `App.vue` (F8) —
separators are the footer's presentation, not the call site's content. Empty slot
collapses via `v-if="$slots.default"`, so admin and docs stop carrying the
10px gap of an empty row.

### D9 — Fix the F11 defects

Correct `"Discrod"`. Make the revision a real, selectable element — visible text
at `--color-gray-light`, or a focusable button that copies it — rather than a
`display: none` span behind a tooltip. Give the offline state a non-opacity
signal (the existing `.online` class can carry a tone from the token set), so it
is not conveyed by opacity alone.

### D10 — Replace the anchor-count assertion

`toHaveLength(4)` (F10) becomes assertions against the social list by
`data-test`, plus a test that the declared props from D3 render, and one for the
copyright year from D7. The Playwright spec keeps working unchanged as long as
`data-test="app-footer"` survives — it must.

## Phases

### Phase 0 — Baseline

Screenshot all three footers — frontend, admin, docs — at desktop, at
`$desktop-breakpoint`, and mobile, plus the frontend footer with the nav open
(`.nav-visible`) and at the 370px breakpoint. The nav-open offset and the
admin/docs empty-links case are the two states most likely to regress silently.

Confirm `Footer.spec.ts` passes before touching anything.

### Phase 1 — API and call sites

D3 and D4: declare props, delete the frontend store import, move the support
button to the slot, update all three `App.vue` call sites. No visual change
intended in this phase — the footer should render identically, which makes it a
clean checkpoint.

### Phase 2 — The frame

D1 and D5: delete the five chrome divs, rebuild the band and the cap pair on the
tokens. This is the change that does the visual work.

### Phase 3 — Layout

D2, D6, D8: the grid, the collapsed media block, the nav offset, the links row.

### Phase 4 — Details and a11y

D7 and D9.

### Phase 5 — Verify

D10's rewritten test, `pnpm test`, `pnpm lint:fix`, `pnpm lint:ts`, the Playwright
suite, and the Phase 0 screenshots re-shot across all three apps.

## Implementation notes

Where the built thing differs from the plan above, and why.

### `SupportBtn` took the slot, rather than the footer emitting

D4 moves the support button out of the shared component. Rather than have
`frontend/App.vue` re-implement the modal opening, `SupportBtn` — which already
existed and already owned that logic for the home page — gained a `variant` prop
and a default slot. The footer's call site passes `bare` and its own label plus
the heart, so the button looks exactly as it did, from one implementation:

```vue
<template #actions>
  <SupportBtn :variant="BtnVariantsEnum.BARE">
    {{ t("labels.supportUs") }}
    <i class="fa fa-heart" />
  </SupportBtn>
</template>
```

The home page's `<SupportBtn :size="md" />` is untouched — the slot falls back to
the label it always showed.

### `--nav-width` lives in `tailwind.css`

D6 needed one definition reachable from all three bundles. It sits in the `:root`
block beside the cap geometry, with the `max-width: 370px` override that
`app-navigation.scss` and `layout.scss` both already implement at that
breakpoint. Those two files keep their literals for now, as D6 allowed: the
footer stops adding a seventh copy, and converting the nav is a separate change.

### The disclaimer became one paragraph

Open question 2, answered in the affirmative while the file was open: the four
hardcoded `<br>` breaks are gone and the legal text now wraps against a
`max-w-[70ch]` column. **This is the one change here that is purely a
presentation judgement rather than a defect fix** — if the four-line block was
deliberate, this is the edit to revert.

### Props are optional, not required

Every call site passes all four (F4), so required props would be defensible - but
optional ones let the unit test mount the component bare, which two of its cases
do.

### The offline signal

D9 asked for a non-opacity signal. `online` now drives the revision's *colour*
(`--color-text` when online, `--color-muted` when not) rather than its opacity,
and the revision value itself is rendered as visible monospace text instead of a
`display: none` span behind a tooltip.

### Verification

`pnpm test` (151, up from 148 — the anchor-count assertion became four cases),
`pnpm lint:fix`, `pnpm lint:ts` and a `bin/vite build` all pass. `data-test`
hooks added for the social list and the version line; `data-test="app-footer"` is
unchanged, so `Footer.spec.ts` still applies.

`Footer.spec.ts` itself is **unrun**: the local e2e harness never boots the SPA,
so that spec fails on its own branch and on `feat/panel-redesign` too, before any
change here. Phase 5's screenshot pass across the three apps is likewise
outstanding — and it matters more for this branch than most, since D1 and D2
change the footer's appearance on every page of all three.

## Open questions

1. **Does the cap belong on a full-width band at all?** D1 says yes at 12%, but
   the caps read as a *frame* signature and the footer is a band with no side
   edges. If Phase 2 shows two ticks floating in the middle of a very wide
   viewport, the alternative is a full-width hairline with no cap — a decision to
   make against the rendered thing, not on paper.
2. **Should the disclaimer's `<br>` breaks become prose?** D2 removes the reason
   they exist. Dropping them changes how the legal text wraps at every width,
   which is cosmetic but worth a deliberate look.
3. **Do admin and docs want a different footer entirely?** F5's coupling suggests
   they were never designed for this one — they render a fansite disclaimer, a
   community logo and an RSI trademark notice on internal admin pages. Out of
   scope; noted because the props fix (D3) makes the question answerable later.
