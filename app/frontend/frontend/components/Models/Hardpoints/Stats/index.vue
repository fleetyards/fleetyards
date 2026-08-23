<script lang="ts">
export default {
  name: "HardpointStats",
};
</script>

<script lang="ts" setup>
import type { HardpointStat } from "@/frontend/composables/useHardpointStats";

type Props = {
  stats: HardpointStat[];
};

defineProps<Props>();
</script>

<template>
  <div v-if="stats.length" class="hardpoint-item__stats">
    <span
      v-for="(stat, index) in stats"
      :key="index"
      class="hardpoint-item__stat"
      :class="{ 'hardpoint-item__stat--wide': stat.wide }"
    >
      <span class="hardpoint-item__stat-k">{{ stat.label }}</span>
      <span class="hardpoint-item__stat-v">{{ stat.value }}</span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
