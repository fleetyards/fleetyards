<script lang="ts">
export default {
  name: "ComponentLeadMetric",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentStats } from "@/frontend/composables/useComponentStats";
import { type Component } from "@/services/fyApi";

type Props = {
  component: Component;
  limit?: number;
};

const props = withDefaults(defineProps<Props>(), { limit: 2 });

const { t } = useI18n();

const stats = useComponentStats(() => props.component);

// Its own component rather than a slot in the table, because the figures come
// from a composable and a cell rendered inside `v-for` cannot call one.
//
// Carries its own label per row: the figure a component leads with depends on
// what it is -- sustained DPS for a gun, cooling rate for a cooler -- so this
// is the one column whose heading cannot sit at the top of it. The columns that
// mean the same thing on every row are the sortable ones beside it.
//
// Filtered before it is sliced: `toNumber` renders a falsy value as "N/A", and
// a component whose headline figure the build does not carry should give the
// slot to the next figure it does have rather than to that.
const leadStats = computed(() => {
  const unavailable = t("labels.notAvailable");

  return stats.value
    .filter((stat) => stat.primary && stat.value && stat.value !== unavailable)
    .slice(0, props.limit);
});
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
