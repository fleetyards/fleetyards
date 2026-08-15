# Btn component redesign

## Goal

Rebuild `shared/components/base/Btn` with a new visual language and a coherent prop API, implemented with Tailwind utilities, and make `Btn` own its own appearance in every nesting context (group, dropdown, toggle, page-actions) instead of being restyled from the outside.

## Context

`Btn` is the most-used component in the codebase and has accumulated a decade of layout escape hatches.

Measured surface (census over `app/frontend`, `*.vue`):

| Metric | Count |
| --- | --- |
| `<Btn>` call sites | 468 |
| Files containing `<Btn>` | 212 |
| `<BtnGroup>` call sites | 39 |
| `<BtnDropdown>` call sites | 34 |
| Stylesheets overriding `panel-btn*` from outside | 17 |
| Tests coupled to the `panel-btn` class | **0** |

Prop usage, ordered:

```
350 size          112 inline        95 v-tooltip     91 data-test
 90 disabled       82 variant       80 to            55 aria-label
 51 loading        50 block         39 active        26 class
 23 mobile-icon-only  21 href       17 type          11 spinner
  8 confirm         6 text-inline    5 exact          4 mobile-block
  3 align-start     1 flush
```

Value distribution for the two dominant props:

```
size:     small 296  |  large 38  |  xsmall 3  |  default 2   (+12 dynamic)
variant:  transparent 25  |  link 25  |  danger 23  |  default 1  (+8 dynamic)
```

## Findings that drive the design

### F1 — The default size is wrong

`size="small"` accounts for **296 of 468** call sites (63%). The component's `default` size is passed explicitly **twice**. The design's default is not the one the app actually wants.

Migration hazard: 118 call sites omit `size` entirely and today render at `default`. Any change to the default silently resizes those 118 sites. This must be handled deliberately (see D1), not as a side effect.

### F2 — `inline` (112 uses) exists only to undo the component's own margin

`Btn` ships `margin-right: 10px; margin-bottom: 20px`. `inline` sets `margin-bottom: 0`. `flush` sets `margin: 0`. A quarter of all call sites pass a prop whose only job is to cancel styling the component should never have applied.

The knock-on damage is visible in `stylesheets/frontend/partials/page-actions.scss`, which is roughly half margin-fighting:

```scss
&.page-actions-left  { & > a, & > button { margin-right: 10px; margin-left: 0; } }
&.page-actions-right { & > a, & > button { margin-right: 0; margin-left: 10px; } }
&.page-actions-block { > .panel-btn { margin-bottom: 20px;
                       &.panel-btn-inline { margin-bottom: 0; } } }
```

Once `Btn` is margin-free and containers use `gap`, most of this file deletes rather than migrates.

### F3 — `variant` conflates chrome with intent

`default | transparent | link | danger` mixes two independent axes: how much chrome the button has (solid / outline-only / none) and what it means (neutral / destructive). There is no way to express a destructive low-emphasis button today.

### F4 — Near-dead props

`flush` (1), `align-start` (3), `mobile-block` (4), `text-inline` (6), `size="xsmall"` (3). Each carries a branch in the template, the class map, and the stylesheet. All are expressible as utilities or a variant.

### F5 — Accessibility defects

- `outline: none` on `.panel-btn:focus` and on `.panel-btn-inner:focus`, with **no `:focus-visible` replacement**. Keyboard focus is invisible.
- `loading` **replaces the label text** with `t("baseBtn.labels.loading")`. The accessible name changes mid-interaction; no `aria-busy`.
- Disabled links are not actually disabled. `btnType` degrades `to` → `button` when disabled, but the `href` branch still renders `<a href>` with a `disabled` attribute, which has no effect on anchors — a disabled link button remains clickable and focusable.
- Hover uses `color: invert($text-color)` against `background-color: $panel-inner-border` — contrast is incidental, not chosen.
- `transition: all $transition-base-speed ease` = **500ms on every property**, including `color` and `background`. Hover feels laggy and it ignores `prefers-reduced-motion`.

### F6 — Outside-in restyling (the nesting problem)

17 stylesheets reach into `panel-btn` internals. They split cleanly:

**Margin-fighting — deletes once F2 is fixed:**
`AppNavigation/Header`, `FilteredList`, `Table/BulkActions`, `page-actions.scss` (frontend + embed), `SocialLogins`, `OauthBtn`, `Vehicles/OwnersModal`.

**Genuine appearance that belongs inside `Btn` — must become real variants:**
- `panel-btn-toggle.scss` — a two-segment toggle that restyles `.panel-btn-inner:first-child` / `:last-child`, including its own active states via `.active-left` / `.active-right`. This is a segmented control masquerading as a stylesheet.
- `erkul.scss` — restyles `.panel-btn-inner` in four places.
- `BtnGroup/index.scss` and `BtnDropdown/index.scss` — reach into `.panel-btn` to join corners and suppress borders between members.

Per the redesign brief, group/dropdown/toggle nesting styles move **into** `Btn`, driven by context the parent provides rather than by descendant selectors.

### F7 — The embed bundle is the main technical risk

`Btn` is used inside the embed (`embed/pages/index.vue`), but the embed is a **self-contained bundle injected into third-party pages**:

```js
// app/views/frontend/embed.js.erb — links exactly one stylesheet
styles.href = '<%= vite_asset_url('embed.scss', type: :stylesheet) %>'
const chunks = ...resolve_entries('embed.ts').fetch(:scripts, [])  // scripts only
```

`embed.scss` namespaces everything under `#fleetyards-view` and does **not** import Tailwind. The vite manifest confirms `entrypoints/embed.ts` carries no entry-level CSS. This is why `stylesheets/embed/partials/panel-btn.scss` exists as a **near-complete duplicate** of the button styles — its own notches, hover, `flash` keyframe and size modifiers.

Consequence: a `Btn` whose appearance comes from Tailwind utility classes in the template will render **unstyled inside embeds on third-party sites**, because Tailwind's generated utilities are not in the embed bundle. Adding `@import "tailwindcss"` to `embed.scss` is not an acceptable fix — Preflight would reset the host page's styles.

Resolution (D3): author the button's appearance as component CSS built from Tailwind's theme via `@reference` + `@apply`, so utilities are **inlined into the component's own stylesheet at build time**. This keeps a single source of truth, satisfies "implemented with Tailwind", and produces plain CSS with no runtime dependency on `tailwind.css` — which the embed can consume. Verification that the embed actually loads component CSS is an explicit gate (see Phase 0).

### F8 — Test coupling is zero

No test references `panel-btn`. E2E hooks on `data-test` (91 call sites) and `aria-label` (55). Both must keep flowing through via `v-bind="$attrs"`. This is the single biggest de-risking fact in the migration.

## Decisions

### D1 — Size scale and the 118 implicit-default call sites — **DECIDED**

Adopt a 3-step scale, renamed to `sm | md | lg`, with **`sm` as the default** (matches 63% of real usage).

**Decided: the 118 sites that omit `size` are left alone and adopt the new smaller default.** The codemod does not pin them to `md`. Rationale — a 48px-min-height button is part of what reads as dated; the refresh intentionally brings the omitted-size baseline down. This is the one change in this plan that is *not* mechanically behaviour-preserving, so it is reviewed on the visual-tests page before the codemod runs.

`xsmall` (3 uses) is dropped; those sites move to `sm`.

End state: `size` is passed at roughly 43 of 468 call sites, down from 350.

### D2 — Split `variant` into `variant` × `tone`

```
variant: solid | ghost | bare      (how much chrome)
tone:    neutral | danger          (what it means)
```

Mapping: `default` → `solid`, `transparent` → `ghost`, `link` + `text-inline` → `bare`, `danger` → `tone="danger"` (keeping whatever variant the site had).

This is composable (destructive-but-quiet becomes expressible) and keeps the color decision in one place for contrast auditing.

### D3 — Tailwind via `@reference` + `@apply` in component CSS — **VERIFIED, with a constraint**

Driven by F7. The button's appearance is authored against the Tailwind theme and inlined at build time, so the compiled output is plain CSS with no runtime dependency on `tailwind.css`.

**The component must use a plain `<style scoped>` block, not `<style lang="scss">`.** This was verified empirically with a minimal vite build using this repo's own toolchain:

- With `lang="scss"`, `@reference` and `@apply` pass through sass untouched and reach the minifier as unrecognised at-rules — the styles are silently dropped:
  ```
  [lightningcss minify] Unknown at rule: @reference
  [lightningcss minify] Unknown at rule: @apply
  ```
- With plain `<style scoped>`, they compile correctly, and theme tokens are emitted **with inline fallbacks**:
  ```css
  .probe[data-v-eb592763]{border-radius:var(--radius-panel,10px);
    border-color:var(--color-panel-edge,#c8c8c8);
    padding-inline:calc(var(--spacing,.25rem) * 4);…}
  ```

The inline fallbacks are what make this work for the embed (F7): the compiled rule is self-sufficient even where `@theme`'s custom properties were never registered on `:root`.

Consequences:
- `Btn` drops `@import "./index.scss"` and the auto-injected SCSS variables (`$text-color`, `$panel-*`) from `vite.config.ts`'s `additionalData`. Its tokens come from the Tailwind `@theme` block instead. This is the intent of the migration, not a workaround.
- Tokens the button needs (radii, ring, sizing, panel colors) are added to `@theme` in `entrypoints/tailwind.css`, which currently defines only breakpoints, colors and one spacing value.
- `@reference` path resolution via the `@` alias is unverified; fall back to a relative path if it fails at real build time.

Trade-off accepted: this forgoes ad-hoc per-call-site utility overrides as the primary styling mechanism. Given 468 call sites need consistency — and `class` is passed at only 26 of them — consistency wins.

### D4 — Group/dropdown context via `provide`/`inject`

`BtnGroup` and `BtnDropdown` provide a context object; `Btn` injects it and self-applies joined-corner / shared-border / segment styling. `BtnGroup/index.scss` and `BtnDropdown/index.scss` stop reaching into `.panel-btn` internals. `panel-btn-toggle` becomes a `BtnGroup` mode rather than a global stylesheet.

`BtnGroup` becomes the owner of inter-button spacing (`gap`), which is what makes F2's margin removal safe.

### D5 — End-caps always on, with a proportional inset — **DECIDED**

The `::before`/`::after` hairlines are Fleetyards' visual signature and are **non-negotiable — a button without caps is not an option.** They are retokenised to `#4a4f54` with `border-radius: 1px` per the metrics-card treatment, and appear at every size and width.

An earlier draft gated them to `md`/`lg` on the `metrics-card--slim` precedent. **Overruled.** Slim is a card at reduced strength; a button is a different component and the motif has to survive at button scale.

That makes the *inset* the thing to get right, because a fixed inset is what made the old caps collapse:

| Button | Old inset 14px each side | Cap remaining |
| --- | --- | --- |
| icon-only, 36px wide | 28px consumed | **8px** |
| icon-only, at an 18px inset | 36px consumed | **0px — invisible** |
| 160px wide | 28px consumed | 132px (83%) |

Replacement — proportional with a floor:

```css
left:  max(10px, 18%);
right: max(10px, 18%);
height: 2px;              /* 3px at lg, matching the card */
```

The cap holds a constant ~64% of the width at any label length, and the 10px floor keeps it clear of the 8px corner radius at the narrowest widths.

Two structural exceptions:

- **Groups** wear one pair of caps spanning the whole control, not a pair per member. Per-member caps are exactly what made rev 1's group look broken (hairlines stacking mid-control). Consequence: `BtnGroup` cannot use `overflow: hidden` — it would clip caps sitting on the border — so member end corners are radiused explicitly instead (inner radius = outer 8px − 1px border = 7px).
- **`bare`** carries no caps, having no border or surface for them to sit on; caps there would float free of any edge.

### D6 — Visual language anchored to `MetricsCard`, not invented — **DECIDED**

Direction A ("refined panel") chosen from a four-way review: it is a clear improvement on today's button while preserving the existing design language and sitting correctly alongside the new metrics cards. Directions considered and rejected: HUD corner-brackets (uppercase tracked labels don't survive six locales), flat/tactical (loses Fleetyards' identity), chamfer-cut via `clip-path` (crops the focus ring).

All values come from `Models/metricsCard.scss` and `Models/MetricsCard/index.vue` rather than being designed fresh:

| Role | Value | Source |
| --- | --- | --- |
| Interactive accent | `$primary` `#428bca` | `metrics-card__toggle` hover border, primary tile rail |
| Edge | `rgba($gray-light, .5)` | `metrics-card` border |
| Divider | `rgba($gray-light, .28)` | `metrics-card__hero` gap fill, `__divider` |
| End-cap | `#4a4f54`, 3px, r1px | `metrics-card::before/::after` |
| Segment fill | `$gray-black` `#222` | `metrics-card__tile` |
| Lifted text | `lighten($text-color, 15%)` | tile value, card title |
| Motion | `150ms ease` | `metrics-card__toggle` |

Two corrections this forced: the interactive accent is **`$primary` blue, not cyan**, and the edge is the cooler, dimmer `$gray-light` at 0.5 — the old `rgba(#c8c8c8, .9)` glare is a large part of what reads as dated.

Rejected sub-variant: promoting `metrics-card__toggle`'s pill (Orbitron, uppercase, tracked, 999px) to the app-wide button. It works as a rare short control inside a card, but tracked uppercase Orbitron across 468 labels breaks German compounds and CJK, and gives the 55 icon-only buttons nothing. The pill stays card-local.

### D7 — `BtnGroup` uses the `metrics-card__hero` pattern — **DECIDED**

Rev 1 of the design review got the group visibly wrong in every direction, because it squeezed fully-chromed buttons together: each member repeated the border *and* the end-caps, stacking hairlines through the middle of the control, plus a `margin-left: -1px` overlap hack.

The correct pattern is already in the codebase at `metrics-card__hero`:

```scss
display: flex;
gap: 1px;                                  // container bg reads as 1px dividers
background: rgba($gray-light, 0.28);
border: 1px solid rgba($gray-light, 0.28);
border-radius: 8px;
overflow: hidden;
```

The **container** owns border and radius; members are flat `$gray-black` fills with no chrome. Selection is a `$primary` tint at 0.22.

One deviation from the hero, forced by D5: `overflow: hidden` has to go, because it would clip the group's end-caps where they sit on the border. Member end corners get explicit radii instead (`7px` — the outer `8px` less the `1px` border).

This is also what D4's "Btn owns its own nesting" means concretely: the member suppresses its own edge and caps in response to injected group context, so `BtnGroup` never writes descendant selectors into `Btn`'s internals — and `panel-btn-toggle.scss` becomes a group mode rather than a global stylesheet.

## Prop API: before → after

| Current | Uses | New | Note |
| --- | --- | --- | --- |
| `size="small"` | 296 | *(omit)* | new default |
| `size="default"` | 2 | `size="md"` | |
| `size="large"` | 38 | `size="lg"` | |
| `size="xsmall"` | 3 | `size="sm"` | dropped |
| `variant="transparent"` | 25 | `variant="ghost"` | |
| `variant="link"` | 25 | `variant="bare"` | |
| `variant="danger"` | 23 | `tone="danger"` | |
| `text-inline` | 6 | `variant="bare"` | |
| `inline` | 112 | **removed** | Btn ships no margin |
| `flush` | 1 | **removed** | |
| `mobile-block` | 4 | `class="w-full md:w-auto"` | |
| `align-start` | 3 | `class="justify-start"` | |
| `block` | 50 | `block` | kept |
| `mobile-icon-only` | 23 | `mobile-icon-only` | kept — hides label, not utility-expressible |
| `active` | 39 | `active` | kept |
| `disabled` / `loading` / `spinner` | 152 | kept | a11y reworked |
| `confirm` | 8 | kept | |
| `to` / `href` / `target` / `exact` / `type` | 118 | kept | |
| `routeActiveClass` | 0 | **removed** | unused |

Net: **20 props → 12**, and the two highest-frequency props (`size`, `inline`) largely disappear from call sites.

## Phases

### Ordering note

Prop API and visual design are **orthogonal**: the API lives in `index.vue`/`types.ts`, the look lives in the component's CSS. So the 468-site codemod (Phase 3) can run before the visuals are final, and iterating on the design afterwards costs nothing. No backward-compatibility aliases are introduced — the codemod lands with the rebuild.

### Phase 0 — De-risk gates

1. ~~**`@apply` pipeline gate.**~~ **Done** — see D3. Verified that `@apply` works in plain `<style scoped>` but is silently dropped under `lang="scss"`.
2. **Embed CSS gate** — *owned by Marten, verifying in the browser.* Whether component scoped CSS reaches the embed bundle at runtime, or whether `Btn`'s styles there come solely from `embed/partials/panel-btn.scss`. **Not blocking the rebuild** — D3's inline fallbacks make the compiled CSS self-sufficient either way. It decides only whether the duplicated embed stylesheet can be deleted in Phase 4 step 15.
3. **Visual baseline.** Expand `visual-tests/buttons.vue` to cover the full matrix (every variant × tone × size × state: default/hover/focus/active/disabled/loading, plus group, dropdown, toggle, block, icon-only). Add the first Playwright snapshot spec for it under `test/playwright/e2e`. This is the regression net for Phases 2–4 — the page has no coverage today.
4. **Theme tokens.** Extend `@theme` in `entrypoints/tailwind.css` with the radii / ring / sizing tokens the button needs.

### Phase 1 — Rebuild the component

4. New `types.ts`: `BtnVariantsEnum` (solid/ghost/bare), new `BtnTonesEnum`, `BtnSizesEnum` (sm/md/lg).
5. New `index.vue`: reduced prop set, `v-bind="$attrs"` pass-through preserved (F8), `inject` of group context (D4), a11y fixes from F5 — `:focus-visible` ring, `aria-busy` + label retained while loading, real disabled semantics for `href` (render `<button>` or add `aria-disabled` + click guard), scoped transitions with `prefers-reduced-motion`.
6. New component CSS per D3. No margins.
7. `Btn/Inner` folded in unless the loader slot justifies keeping it.

### Phase 2 — Group, dropdown, toggle

8. `BtnGroup` provides context + owns `gap`; adds a segmented mode absorbing `panel-btn-toggle`.
9. `BtnDropdown` provides context; stops reaching into `.panel-btn`.
10. Delete `stylesheets/frontend/partials/panel-btn-toggle.scss`; migrate its call sites.

### Phase 3 — Codemod the 468 call sites

11. Script the mechanical mappings from the table above (`size="small"` → omit, `variant` → `variant`/`tone`, strip `inline`/`flush`, `align-start`/`mobile-block` → classes). Handle the ~20 dynamic bindings (`:variant="btnVariant"`, ternaries) by hand — the census lists them.
12. Run `prettier --write` on touched frontend files, then `eslint`. Prettier is a separate CI gate.

### Phase 4 — Un-leak the 17 stylesheets

13. Delete margin-fighting blocks now made redundant (F6 group 1), converting containers to `gap`. `page-actions.scss` shrinks substantially.
14. Fold remaining appearance overrides (`erkul.scss`, `OwnersModal`) into variants or scoped exceptions.
15. Reconcile `stylesheets/embed/partials/panel-btn.scss` per the Phase 0 gate outcome.

### Phase 5 — Verify

16. Playwright snapshots green; review intentional diffs (notably the 118 implicit-size sites per D1).
17. `pnpm test`, `pnpm test:e2e:run`, embed test page checked in a browser on a light and a dark host page.
18. `knip` for newly-dead exports (`routeActiveClass`, dropped enum members).

## Open questions

- ~~**Q1** Does the notch motif survive at `sm`?~~ Resolved by D5 — caps are always on; the inset became proportional so they hold up at every width.
- ~~**Q2** Shrink or pin the 118 implicit-size call sites?~~ Resolved by D1 — let them shrink.
- **Q3** Should `tone` extend beyond `neutral | danger` — is there demand for `success` / `warning`? No current call site needs it.
- **Q4** `$primary` is now the hover signal on every button. Confirm that doesn't collide with `$primary`'s existing role as the *primary metrics tile* accent rail — i.e. that a hovered button and a highlighted stat don't read as the same kind of emphasis.

## Design review

Interactive review of the chosen direction, with a state/size rig and the rebuilt group:
<https://claude.ai/code/artifact/6834db12-c4be-496b-ab14-caffbbb01d2e>
