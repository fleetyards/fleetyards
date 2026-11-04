<script lang="ts">
export default {
  name: "ComponentLeadMetric",
};
</script>

<script lang="ts" setup>
import { useAvailableComponentStats } from "@/frontend/composables/useComponentStats";
import { type Component } from "@/services/fyApi";

type Props = {
  component: Component;
  limit?: number;
};

const props = withDefaults(defineProps<Props>(), { limit: 4 });

const stats = useAvailableComponentStats(() => props.component);

// Carries its own label per row: the figure a component leads with depends on
// what it is -- sustained DPS for a gun, cooling rate for a cooler. The headline
// figures come first, then whatever else it has, so a part with one headline
// figure still fills the row.
const leadStats = computed(() =>
  [
    ...stats.value.filter((stat) => stat.primary),
    ...stats.value.filter((stat) => !stat.primary),
  ].slice(0, props.limit),
);
</script>

<template>
  <span v-if="leadStats.length" class="component-lead-metric">
    <span
      v-for="stat in leadStats"
      :key="stat.label"
      class="component-lead-metric__item"
    >
      <span class="component-lead-metric__label">{{ stat.label }}</span>
      <span class="component-lead-metric__value">{{ stat.value }}</span>
    </span>
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
