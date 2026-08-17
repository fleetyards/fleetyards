<script lang="ts">
export default {
  name: "BasePanelHeading",
};
</script>

<script lang="ts" setup>
import {
  PanelHeadingShadowEnum,
  PanelHeadingTonesEnum,
} from "@/shared/components/base/Panel/Heading/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";

type Props = {
  shadow?: `${PanelHeadingShadowEnum}`;
  level?: HeadingLevelEnum;
  size?: HeadingSizeEnum;
  tone?: `${PanelHeadingTonesEnum}`;
  // Reduced padding and type, for a heading on a `slim` panel.
  compact?: boolean;
  // A rule under the heading, so a slim panel's head still reads as a head
  // without the full frame's weight behind it.
  divider?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  shadow: undefined,
  level: HeadingLevelEnum.H1,
  size: HeadingSizeEnum.XXL,
  tone: PanelHeadingTonesEnum.DEFAULT,
  compact: false,
  divider: false,
});

const slots = defineSlots<{
  default: [];
  subtitle: [];
  actions: [];
}>();

const isMetric = computed(() => props.tone === PanelHeadingTonesEnum.METRIC);
</script>

<template>
  <div
    class="panel-heading"
    :class="{
      'panel-heading--top': shadow === 'top',
      'panel-heading--bottom': shadow === 'bottom',
      'panel-heading--metric': isMetric,
      'panel-heading--compact': compact,
      'panel-heading--divider': divider,
    }"
  >
    <!--
      The metric tone is its own markup rather than a restyled Heading: the
      tracked uppercase Orbitron label is a span with a status dot, not a
      document heading, and running it through Heading would mean overriding
      every type property the component sets.
    -->
    <span v-if="isMetric" class="panel-heading__metric-title">
      <span class="panel-heading__dot" />
      <span data-test="panel-heading-title"><slot name="default" /></span>
    </span>

    <Heading
      v-else
      :level="level"
      :size="size"
      hero
      shadow
      class="panel-heading__title"
      data-test="panel-heading-title"
      :class="{
        'panel-heading__title--with-actions': slots.actions,
      }"
    >
      <template #default>
        <slot name="default" />
      </template>
      <template v-if="slots.subtitle" #subHeading>
        <slot name="subtitle" />
      </template>
    </Heading>

    <div v-if="slots.actions" class="panel-heading__actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<style scoped>
@reference "../../../../../entrypoints/tailwind.css";

/*
 * Padding pairs with PanelBody's 4px 18px 18px. The old 15px 15px 0 closed the
 * heading flush, so every body under one opened with a redundant 15px of its
 * own - which is the whole reason `no-padding-top` was passed at 12 sites.
 */
.panel-heading {
  @apply relative flex justify-between text-text;
  padding: 16px 18px 12px;
}

/* A scrim for a heading sitting over a background image. Absorbs what the
   deleted PanelShadow component did from inside the panel body. */
.panel-heading--top {
  @apply items-start;
  border-top-left-radius: var(--radius-surface-inner, 14px);
  border-top-right-radius: var(--radius-surface-inner, 14px);
  background: linear-gradient(to bottom, rgb(0 0 0 / 0.8), transparent);
}

.panel-heading--bottom {
  @apply items-end;
  border-bottom-left-radius: var(--radius-surface-inner, 14px);
  border-bottom-right-radius: var(--radius-surface-inner, 14px);
  background: linear-gradient(to top, rgb(0 0 0 / 0.8), transparent);
}

.panel-heading__title {
  @apply w-full;
  padding: 0;
}

.panel-heading__title--with-actions {
  padding-right: 37px;
}

.panel-heading__actions {
  @apply absolute right-0 top-0;
  margin-right: 10px;
  padding-top: 10px;
}

.panel-heading--compact {
  padding: 14px 16px;
}

.panel-heading--divider {
  border-bottom: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  background: rgb(0 0 0 / 0.12);
}

/*
 * The metrics-card title: Orbitron, tracked, uppercase, with a gold status dot.
 * Kept to this tone rather than made the panel default - it works because a
 * metrics card's labels are short and fixed, and tracked uppercase across
 * free-form ship names breaks German compounds and CJK, which is the same call
 * the Btn redesign made about button labels.
 */
.panel-heading--metric {
  @apply items-center;
  gap: 12px;
  flex-wrap: wrap;
}

/*
 * In flow, opposite the title. A document heading pins its actions to the
 * corner because the title runs the full width under them; a metric head is one
 * short label, so its actions sit beside it.
 */
.panel-heading--metric .panel-heading__actions {
  @apply static;
  margin: 0;
  padding: 0;
}

.panel-heading--compact .panel-heading__metric-title {
  font-size: 13px;
}

.panel-heading__metric-title {
  @apply flex items-center text-lifted;
  gap: 11px;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 15px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
}

.panel-heading__dot {
  @apply flex-none rounded-full bg-gold;
  width: 7px;
  height: 7px;
  box-shadow: 0 0 10px 1px rgb(212 175 55 / 0.55);
}
</style>
