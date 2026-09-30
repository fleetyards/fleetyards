<script lang="ts">
export default {
  name: "ComponentStatGroups",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { StatGroup } from "./types";

type Props = {
  groups: StatGroup[];
  testPrefix?: string;
};

withDefaults(defineProps<Props>(), {
  testPrefix: "stat-group",
});
</script>

<template>
  <MetricsCard
    v-for="group in groups"
    :key="group.key"
    :title="group.title"
    variant="slim"
    :data-test="`${testPrefix}-${group.key}`"
  >
    <div class="metrics-card__rows">
      <div
        v-for="stat in group.stats"
        :key="stat.label"
        class="metrics-card__row"
      >
        <span class="metrics-card__row__label">{{ stat.label }}</span>
        <span class="metrics-card__row__value">{{ stat.value }}</span>
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
