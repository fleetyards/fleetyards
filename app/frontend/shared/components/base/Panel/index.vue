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
}));

// The inner box only earns its place when it has a job: a row context for
// `alignment`, or a padding context for `inset`. Otherwise the panel is one box.
const hasInner = computed(() => !!props.alignment || props.inset);
</script>

<template>
  <div class="panel" :class="cssClasses">
    <PanelBgImage v-if="bgImage" :image="bgImage" :rounded="bgRounded" />

    <template v-if="hasInner">
      <div
        class="panel__inner"
        :class="{
          'panel__inner--inset': inset,
          'panel__inner--left': alignment === 'left',
          'panel__inner--right': alignment === 'right',
        }"
      >
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
  @apply absolute bg-endcap;
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

.panel--bare {
  @apply border-transparent bg-transparent;
  box-shadow: none;
}

.panel--bare::before,
.panel--bare::after {
  content: none;
}

.panel--translucent {
  background-color: rgb(39 43 48 / 0.6);
}

/* ---------- tone ---------- */

.panel--primary {
  @apply border-primary;
}

.panel--success {
  border-color: #4cae4c;
}

.panel--error {
  border-color: #c00;
}

.panel--highlight {
  @apply border-gold;
}

.panel--animated.panel--error {
  animation: panel-error 1s infinite ease alternate;
}

.panel--animated.panel--success {
  animation: panel-success 1s infinite ease alternate;
}

/* ---------- layout ---------- */

/*
 * Spacing stays, unlike Btn's. A button is an inline control dropped into flex
 * rows that own their gap, which is why 112 sites passed `inline` to cancel its
 * margin; a panel is a block-level surface stacked vertically and 89 of 91 sites
 * want this. What went is the arithmetic it used to force on fill-height.
 */
.panel--outer-spacing {
  margin-bottom: 21px;
}

/*
 * align-self rather than height:100% + calc(100% - 21px): the old rule had to
 * subtract its own margin from its own height. Stretching in the flex column
 * leaves the margin out of it entirely.
 */
.panel--fill-height {
  display: flex;
  flex-direction: column;
  align-self: stretch;
  height: 100%;
}

.panel--fill-height.panel--outer-spacing {
  height: calc(100% - 21px);
}

.panel__inner {
  @apply relative flex flex-col;
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

@keyframes panel-error {
  from {
    border-color: rgb(204 0 0 / 0.5);
  }
  to {
    border-color: rgb(204 0 0 / 1);
  }
}

@keyframes panel-success {
  from {
    border-color: rgb(76 174 76 / 0.5);
  }
  to {
    border-color: rgb(76 174 76 / 1);
  }
}

@media (prefers-reduced-motion: reduce) {
  .panel {
    transition-duration: 0ms;
  }

  .panel--animated.panel--error,
  .panel--animated.panel--success {
    animation: none;
  }
}
</style>
