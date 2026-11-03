<script lang="ts">
export default {
  name: "VisualTestsGearStatsPage",
};
</script>

<script lang="ts" setup>
import EquipmentGearStats from "@/frontend/components/Equipment/GearStats/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { GEAR } from "@/frontend/components/Equipment/GearStats/visual/fixtures";
</script>

<template>
  <div class="gear-stats-visual">
    <section
      v-for="item in GEAR"
      :key="item.key"
      class="gear-stats-visual__item"
      :data-test="`gear-${item.key}`"
    >
      <Heading level="h1" size="xl" mt>{{ item.name }}</Heading>
      <EquipmentGearStats :stats="item.stats" />
    </section>
  </div>
</template>

<style lang="scss" scoped>
.gear-stats-visual__item {
  padding-bottom: 32px;
}
</style>
