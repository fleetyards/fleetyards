<script lang="ts">
export default {
  name: "FleetSquadronBadge",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import type { FleetSquadronRef } from "@/services/fyApi";

type Props = {
  squadron: FleetSquadronRef;
  to?: RouteLocationRaw;
};

const props = defineProps<Props>();

// A squadron without a colour gets the quiet grey a glyph takes, not a
// coloured swatch that would claim somebody chose it.
const dotStyle = computed(() => ({
  backgroundColor: props.squadron.color || "var(--color-muted)",
}));
</script>

<template>
  <component
    :is="props.to ? 'router-link' : 'span'"
    :to="props.to"
    class="squadron-badge"
    :data-test="`squadron-badge-${props.squadron.slug}`"
  >
    <span class="squadron-badge-dot" :style="dotStyle" />
    {{ props.squadron.name }}
  </component>
</template>

<style lang="scss" scoped>
.squadron-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 2px 8px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  font-size: 0.8em;
  line-height: 1.5;
  white-space: nowrap;
  color: var(--color-text-dim);
  text-decoration: none;
}

a.squadron-badge:hover {
  color: var(--color-text);
  border-color: var(--color-primary);
}

.squadron-badge-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}
</style>
