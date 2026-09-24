# Panel, Button and Chip Design Language

**Date:** 2026-09-24 (research during the Btn, Panel and filter-label redesigns)

`Panel`, `Btn` and `Chip` share one surface language, taken from `MetricsCard` rather than designed fresh: a single frame, a quiet `--color-edge`, and a pair of end-caps as the signature. This note keeps the measurements and the reasons behind the settled values, so the next change to a surface does not re-litigate them or undo one without knowing what it was for.

## A solid button on a panel is the same fill as the panel

```
$panel-bg / --color-surface  = rgb(39 43 48 / .9)
--color-control              = rgb(39 43 48 / .9)
```

Byte-identical. A `variant="solid"` button on a panel is distinguished from its background only by its edge and end-caps. This is known and left as is rather than deduplicated or stepped apart: the cap is what carries the control, which is one reason the cap colour had to become loud (below). If a surface ever needs a button to read as a raised block, one of the two fills has to move; do not "fix" it by merging the tokens, since they mean different things.

## End-caps: settled values

```css
left: max(10px, 12%); /* --cap-inset */
right: max(10px, 12%);
height: 4px; /* --cap-h */
background: var(--color-endcap); /* #7a8288 */
::before {
  border-radius: 0 0 3px 3px;
} /* inward edge only */
::after {
  border-radius: 3px 3px 0 0;
}
```

- **Proportional inset, with a floor.** The old panel caps were fixed insets (40px and 80px per side, two concentric pairs), so they shrank to 45% of a `col-md-4` panel, 38% at `col-sm-6`, and vanished entirely at 160px. At 12% the cap holds ~76% of the width at any width. The 10px floor keeps it clear of the corner radius on narrow controls; it binds below ~83px, so icon-only and very short buttons keep the floor.
- **`#7a8288`, not `#4a4f54`.** The old value sat 3–5 points of luminance above the panel fill, making the signature the least visible thing on the frame. `#7a8288` is `$gray-light` — `--color-edge` at full opacity — so the cap is the brightest part of the frame without adding another grey. The token is shared by `Panel` and `Btn` on purpose: a panel cap and a button cap are one motif.
- **Inward-edge radius only.** The outward edge stays a crisp line continuous with the border; the side facing into the surface softens. Rounding only one side also lifts the radius clamp to the full cap height. `3px` on a 4px cap is soft without becoming a lozenge floating on the edge.
- **Rejected: fading the ends** with a horizontal gradient. It costs the cap measurable length, undercutting the constant-share property the inset exists for. The inward radius does the softening instead.

Buttons derive from the panel values rather than hard-coding their own, so a change to `--cap-*` keeps everything in step (hard-coding is how `MetricsCard` and the first `Btn` drifted to all-corner rounding):

```
--cap-h-btn     max(2px, cap-h - 2px)                 2px   sm / md
--cap-h-btn-lg  max(2px, cap-h - 1px)                 3px   lg
--cap-r-btn     min(cap-r × 0.5,  cap-h-btn / 2)      1px
--cap-r-btn-lg  min(cap-r × 0.75, cap-h-btn-lg / 2)   1.5px
```

A 43px control cannot carry a 4px hairline, hence the lower heights. The half-height ceiling binds at both button sizes; without it the proportional step lands at 1.5px on a 2px cap, which reads as a lozenge. The panel keeps 0.75× its cap height instead of the same ceiling because a 2px radius on a 4px cap looks under-rounded — deliberate, not an oversight.

Where there are no caps, and why:

- `Panel variant="slim"` — a grid of repeated slim cards is where a cap this loud turns to noise.
- `Btn variant="bare"` — no border or surface for a cap to sit on.
- `BtnGroup` members — the group wears one pair spanning the whole control. Per-member caps stack hairlines through the middle. The group cannot use `overflow: hidden` (it would clip the caps on the border), so member end corners are radiused explicitly: outer 8px less the 1px border = 7px.
- `Chip` — a wrapping row of a dozen pills is denser repetition than any card grid. Fixed 10px insets on content-sized pills also left the `+` button (~30px) with a 10px cap. The cap stays the signature of a _surface_ (panel, band, dropdown), not of every clickable thing.

Caps are otherwise non-negotiable on buttons at every size: an early draft gated them to `md`/`lg`, and that was overruled.

## Variant × tone, and tone colours the cap only

```
Panel  variant: default | slim         tone: neutral | primary | success | error | highlight
Btn    variant: solid | ghost | bare   tone: neutral | danger
```

`variant` is how much chrome; `tone` is what it means. The old single `variant` mixed the two, so a destructive low-emphasis button was not expressible.

Tone recolours the **end-cap**, not the frame. Recolouring the whole border made a validation error the loudest thing in the viewport and threw away the quiet neutral frame the redesign was for. Three treatments were compared — whole edge, whole cap, a 1–2px line on the cap's outward face — and the whole cap won. Each tone only declares `--tone`, so the treatment lives in one place, and the `animated` error/success states pulse the cap's opacity so one keyframe pair serves every tone.

Consequences accepted:

- `slim` has no caps, so its **edge** takes the tone. One tone reads two ways depending on variant; giving slim caps back would undo why it exists.
- On `Btn`, `bare`, grouped and menu-item buttons set `content: none` on their caps, so a danger tone there has no resting marker and relies on its hover tint. An earlier button design carried danger in a pink label (`#f0a8ae`) instead; it was dropped because pink text on the neutral surface read as disabled or errored rather than as an available action.

Hover, press and focus on a button likewise **light the cap and leave the frame alone** (cap goes `$primary`; press dims it to 60%). Recolouring the border swapped the entire outline, which in a toolbar reads as the button changing shape rather than responding. A danger button floods red on hover, so its cap goes white instead of blue.

## No `filled` tone; stat panels are tiles

The old `bgColor="primary"` had two direct call sites, but one was `StatsPanel`, rendered 69 times — laid out four-up, up to sixteen saturated `$primary` blocks on one page. Carrying that forward as a `filled` tone would have kept the loudest thing in the UI under a new name.

The metrics language already had the answer: `metrics-card__tile` emphasises one figure with a 3px `$primary` gradient rail on a `$gray-black` fill. `StatsPanel` became that tile (slim frame, rail, Orbitron tabular figure), built on `metricsCard.scss`'s primitives so the two stay in step. The filled axis was deleted rather than renamed, and those 69 panels were also the narrowest ones, where the fixed-inset cap collapse was worst.

Collapsing each row of four stats into one shared `__hero--grid` panel was proposed and rejected: a tile in its own frame reads as a discrete figure, which is what a stats page is a list of; a shared hero implies four facets of one measurement.

## Chips

`Chip` (the hangar group/classification filter pills) is one box, 1px `--color-edge-soft`, 6px radius, no caps. States are tinted, not inverted: included `rgb(66 139 202 / .22)` fill with `/ .5` edge, excluded the same in `--color-danger`, text unchanged in all three so hover stays distinguishable from selected. The old `invert($text-color)` flip produced dark text on a near-white fill, louder than any other control. The tri-state carries an icon (check / minus) so it is not colour-only.

The tri-state lives in the query string and `useFilters` debounces that write, so a double-click on a chip yields one transition, not two. Tests clicking twice must assert between clicks.

## Shared values and motion

The language was anchored on `MetricsCard`, not invented: `$primary` `#428bca` as the interactive accent (not cyan), edge `rgba($gray-light, .5)`, divider `rgba($gray-light, .28)`, `$gray-black` segment fill, `150ms ease`. The old `rgba(#c8c8c8, .9)` edge glare and the 500ms `transition: all` were a large part of what read as dated. Metrics-card's tracked-uppercase Orbitron pill was rejected as the app-wide button: it breaks German compounds and CJK across hundreds of labels and gives icon-only buttons nothing.

Directions rejected for the button: HUD corner brackets (tracked uppercase labels do not survive six locales), flat/tactical (loses the identity), chamfer cuts via `clip-path` (crop the focus ring).

## Build constraint

Component styles use plain `<style scoped>` with `@reference` + `@apply`. Under `lang="scss"` both at-rules pass through sass untouched and lightningcss silently drops them. Plain CSS compiles theme tokens with inline fallbacks, which the embed bundle needs: it never registers `:root` and cannot import Tailwind without Preflight resetting the host page. For the same reason, every bare `var()` in these components spells out its fallback.
