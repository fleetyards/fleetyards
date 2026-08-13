<script lang="ts">
export default {
  name: "BasePanelBody",
};
</script>

<script lang="ts" setup>
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";

type Props = {
  rounded?: `${PanelRoundedEnum}`;
};

withDefaults(defineProps<Props>(), {
  rounded: undefined,
});
</script>

<template>
  <div
    class="panel-body"
    :class="{
      'panel-body--rounded': rounded === 'all',
      'panel-body--rounded-top': rounded === 'top',
      'panel-body--rounded-right': rounded === 'right',
      'panel-body--rounded-bottom': rounded === 'bottom',
      'panel-body--rounded-left': rounded === 'left',
    }"
  >
    <slot />
  </div>
</template>

<style scoped>
@reference "../../../../../entrypoints/tailwind.css";

/*
 * Paired with PanelHeading's 16px 18px 12px, which is what removes the reason
 * `no-padding-top` existed at 12 call sites: the heading used to close flush at
 * 0 and the body then opened with another 15px under it. Values from
 * MetricsCard, which got this pair right.
 *
 * `no-min-height` is gone too. It was passed at 16 sites and never did anything
 * - there was no class for it in the map and no rule in the stylesheet.
 */
.panel-body {
  @apply relative overflow-hidden;
  padding: 4px 18px 18px;
  transition: border-radius 150ms ease;
}

/*
 * The nested `a` rules exist because a rounded body clips a full-bleed link
 * (an image tile) that would otherwise square off the corner it sits in.
 */
.panel-body--rounded,
.panel-body--rounded :deep(a) {
  border-radius: var(--radius-surface-inner, 14px);
}

.panel-body--rounded-top,
.panel-body--rounded-top :deep(a) {
  border-top-left-radius: var(--radius-surface-inner, 14px);
  border-top-right-radius: var(--radius-surface-inner, 14px);
}

.panel-body--rounded-right,
.panel-body--rounded-right :deep(a) {
  border-top-right-radius: var(--radius-surface-inner, 14px);
  border-bottom-right-radius: var(--radius-surface-inner, 14px);
}

.panel-body--rounded-bottom,
.panel-body--rounded-bottom :deep(a) {
  border-bottom-left-radius: var(--radius-surface-inner, 14px);
  border-bottom-right-radius: var(--radius-surface-inner, 14px);
}

.panel-body--rounded-left,
.panel-body--rounded-left :deep(a) {
  border-top-left-radius: var(--radius-surface-inner, 14px);
  border-bottom-left-radius: var(--radius-surface-inner, 14px);
}

.panel-body--rounded :deep(a),
.panel-body--rounded-top :deep(a),
.panel-body--rounded-right :deep(a),
.panel-body--rounded-bottom :deep(a),
.panel-body--rounded-left :deep(a) {
  @apply overflow-hidden;
}
</style>
