<script lang="ts">
export default {
  name: "BasePanel",
};
</script>

<script lang="ts" setup>
import PanelBgImage from "@/shared/components/base/Panel/BgImage/index.vue";
import {
  PanelVariantsEnum,
  PanelTonesEnum,
  PanelAlignmentsEnum,
  PanelRoundedEnum,
} from "@/shared/components/base/Panel/types";

type Props = {
  alignment?: `${PanelAlignmentsEnum}`;
  animated?: boolean;
  bgImage?: string;
  bgRounded?: `${PanelRoundedEnum}`;
  fillHeight?: boolean;
  inset?: boolean;
  outerSpacing?: boolean;
  tone?: `${PanelTonesEnum}`;
  translucent?: boolean;
  variant?: `${PanelVariantsEnum}`;
};

const props = withDefaults(defineProps<Props>(), {
  alignment: undefined,
  animated: false,
  bgImage: undefined,
  bgRounded: PanelRoundedEnum.ALL,
  fillHeight: false,
  inset: false,
  outerSpacing: true,
  tone: PanelTonesEnum.NEUTRAL,
  translucent: false,
  variant: PanelVariantsEnum.DEFAULT,
});

const cssClasses = computed(() => ({
  [`panel--${props.variant}`]: true,
  [`panel--${props.tone}`]: props.tone !== PanelTonesEnum.NEUTRAL,
  "panel--animated": props.animated,
  "panel--fill-height": props.fillHeight,
  "panel--outer-spacing": props.outerSpacing,
  "panel--translucent": props.translucent,
  "panel--has-bg": !!props.bgImage,
}));

// The inner box only earns its place when it has a job: a row context for
// `alignment`, a padding context for `inset`, or - the important one - a
// containing block for a background image, which must cover the default slot and
// stop there. With the image parented to `.panel` it bled behind the footer, so a
// card's collapsed detail panel wore the ship photo too.
const hasInner = computed(
  () => !!props.alignment || props.inset || !!props.bgImage,
);
</script>

<template>
  <div class="panel" :class="cssClasses">
    <template v-if="hasInner">
      <div
        class="panel__inner"
        :class="{
          'panel__inner--inset': inset,
          'panel__inner--left': alignment === 'left',
          'panel__inner--right': alignment === 'right',
        }"
      >
        <PanelBgImage v-if="bgImage" :image="bgImage" :rounded="bgRounded" />
        <slot name="default" />
      </div>
    </template>
    <slot v-else name="default" />

    <slot name="footer" />
  </div>
</template>

<style scoped>
@reference "../../../../entrypoints/tailwind.css";

/*
 * One box. The old component wrapped a 2px/radius-24 `.panel-wrapper` around a
 * 3px/radius-20 `.panel` around a radius-16 `.panel-inner` — four borders and
 * four end-cap hairlines at two different insets for a single surface. Every
 * value here comes from the metrics-card language rather than being designed
 * fresh; see docs/exec-plans/panel-redesign.md.
 *
 * `.panel` keeps its class name deliberately: Home.spec.ts locates panels with
 * it, and it is the one piece of this component's markup that is contract.
 */
.panel {
  @apply relative bg-surface rounded-surface border-2 border-edge text-text;
  box-shadow: var(--shadow-surface, 0 6px 18px -12px rgb(0 0 0 / 0.8));
  /* Was $transition-base-speed - 500ms on border-color alone felt broken. */
  transition: border-color 150ms ease;
  font-family: "Open Sans", sans-serif;
}

/*
 * End-caps, inset proportionally so the cap holds a constant share of the width
 * instead of collapsing on a narrow panel: the old fixed 80px each side left
 * nothing at all below 160px, and 45% of the width at the col-md-4 the ship grid
 * actually uses. The 10px floor keeps it clear of the corner radius.
 *
 * Rounded on the inward edge only - the top cap rounds its bottom corners and
 * the bottom cap its top - so the outward edge stays a line continuous with the
 * border. The old component did this and both MetricsCard and Btn dropped it.
 *
 * The var() fallbacks are load-bearing, not decorative: Tailwind inlines
 * fallbacks for its own theme utilities, but not for a bare var() written by
 * hand, and the embed bundle never registers :root. See the plan's F8.
 */
.panel::before,
.panel::after {
  content: "";
  /*
   * Above the background image. ::before is generated ahead of the element's
   * children, so with both at z-index auto it painted *under* PanelBgImage -
   * which is inset to the padding box and so covered the inner 2px of the top
   * cap while the bottom cap, generated after the children, stayed whole. The
   * result on every card with a bg-image was one 2px cap and one 4px cap.
   */
  @apply absolute z-[1] bg-endcap;
  left: max(10px, var(--cap-inset, 12%));
  right: max(10px, var(--cap-inset, 12%));
  height: var(--cap-h, 4px);
}

.panel::before {
  top: -2px;
  border-radius: 0 0 var(--cap-r, 3px) var(--cap-r, 3px);
}

.panel::after {
  bottom: -2px;
  border-radius: var(--cap-r, 3px) var(--cap-r, 3px) 0 0;
}

/* ---------- variants ---------- */

.panel--slim {
  @apply rounded-surface-slim border;
  box-shadow: var(--shadow-surface-slim, 0 6px 20px -14px rgb(0 0 0 / 0.9));
}

/* A grid of repeated cards is exactly where a cap this loud turns to
   noise, which is the same call metrics-card--slim already made. */
.panel--slim::before,
.panel--slim::after {
  content: none;
}

.panel--translucent {
  background-color: rgb(39 43 48 / 0.6);
}

/* ---------- tone ----------
 * The cap carries the tone; the frame stays neutral. Recolouring the whole edge
 * made a validation error the loudest thing in the viewport and threw away the
 * quiet frame this redesign is for, so the signature carries the meaning instead.
 *
 * Each tone only declares --tone. Fallbacks are spelled out because a bare var()
 * gets none from Tailwind and the embed never registers :root.
 */
.panel--primary {
  --tone: var(--color-primary, #428bca);
}

.panel--success {
  --tone: #4cae4c;
}

.panel--error {
  --tone: #c00;
}

.panel--highlight {
  --tone: var(--color-gold, #d4af37);
}

.panel--primary::before,
.panel--primary::after,
.panel--success::before,
.panel--success::after,
.panel--error::before,
.panel--error::after,
.panel--highlight::before,
.panel--highlight::after {
  background-color: var(--tone);
}

/*
 * `slim` has no caps, so a cap-carried tone has nothing to sit on and its edge
 * has to take it. That does mean one tone reads two ways depending on variant -
 * an accepted limitation of putting tone on the cap, not an oversight.
 */
.panel--slim.panel--primary,
.panel--slim.panel--success,
.panel--slim.panel--error,
.panel--slim.panel--highlight {
  border-color: var(--tone);
}

.panel--animated.panel--error::before,
.panel--animated.panel--error::after,
.panel--animated.panel--success::before,
.panel--animated.panel--success::after {
  animation: panel-cap-pulse 1s infinite ease alternate;
}

.panel--animated.panel--slim.panel--error,
.panel--animated.panel--slim.panel--success {
  animation: panel-edge-pulse 1s infinite ease alternate;
}

/* ---------- layout ---------- */

/*
 * Spacing stays, unlike Btn's. A button is an inline control dropped into flex
 * rows that own their gap, which is why 112 sites passed `inline` to cancel its
 * margin; a panel is a block-level surface stacked vertically and 89 of 91 sites
 * want this.
 */
.panel--outer-spacing {
  margin-bottom: 21px;
}

/*
 * min-height, not height. A Bootstrap column stretches to the tallest in its
 * flex line, so a percentage minimum fills that line - which is the equal-height
 * behaviour the 286px floor was standing in for - while still growing past it
 * when the content needs more.
 *
 * `height: 100%` cannot do that. It resolves against the column, and the column
 * is as tall as *all* its children, so a panel with a sibling (a heading above
 * it, say) got locked to a height smaller than its own content and spilled out
 * over whatever followed.
 *
 * The margin is still subtracted so that panel plus margin fills the line rather
 * than overflowing it by 21px.
 */
.panel--fill-height {
  display: flex;
  flex-direction: column;
  min-height: 100%;
}

.panel--fill-height.panel--outer-spacing {
  min-height: calc(100% - 21px);
}

.panel__inner {
  @apply relative flex flex-col;
}

/*
 * A background image contributes no height, so a card whose content is a title
 * and two chips would collapse to text height and the photo would disappear.
 *
 * The floor sits on the image region, not on the card. On the card it only
 * created slack while the card was short: as soon as a footer had content of its
 * own the card outgrew 290px, the slack was gone, and the region fell back to
 * its content height - collapsing the photo and clipping the body under it. This
 * is where production carried it too, as `.panel-inner { min-height: 286px }`.
 *
 * Overridable per card through --panel-image-height, which inherits, so a
 * consumer never has to reach into this component to change it.
 */
.panel--has-bg {
  display: flex;
  flex-direction: column;
}

.panel--has-bg > .panel__inner {
  min-height: var(--panel-image-height, 286px);
}

/*
 * 1 0 auto, never `flex: 1`. That shorthand is 1 1 0%, and a flex item's
 * automatic minimum size is its *content-based* minimum - which is 0 for a
 * scroll container. `.panel-body` sets overflow: hidden, so the inner was free
 * to collapse to roughly the heading's height once the footer had any content of
 * its own, shrinking the photo and clipping the body it was holding.
 *
 * Growing from the content's own height fills a stretched card without ever
 * shrinking below what is in it.
 */
.panel--has-bg > .panel__inner {
  flex: 1 0 auto;
}

.panel__inner--inset {
  padding: 20px 20px 0;
}

.panel__inner--left,
.panel__inner--right {
  @apply flex-row;
}

.panel__inner--left > :first-child {
  flex: 30% 0 0;
}

.panel__inner--left > :last-child {
  flex: 1;
}

.panel__inner--right > :last-child {
  flex: 30% 0 0;
}

.panel :deep(table) {
  margin-bottom: 0;
}

.panel :deep(table:first-child tbody:first-child tr:first-child td),
.panel :deep(table:first-child thead tr:first-child th) {
  border-top: none;
}

/* Pulses the tone itself, so one pair of keyframes serves every tone. */
@keyframes panel-cap-pulse {
  from {
    opacity: 0.45;
  }
  to {
    opacity: 1;
  }
}

@keyframes panel-edge-pulse {
  from {
    border-color: color-mix(in srgb, var(--tone) 45%, transparent);
  }
  to {
    border-color: var(--tone);
  }
}

@media (prefers-reduced-motion: reduce) {
  .panel {
    transition-duration: 0ms;
  }

  .panel--animated.panel--error::before,
  .panel--animated.panel--error::after,
  .panel--animated.panel--success::before,
  .panel--animated.panel--success::after,
  .panel--animated.panel--slim.panel--error,
  .panel--animated.panel--slim.panel--success {
    animation: none;
  }
}
</style>
