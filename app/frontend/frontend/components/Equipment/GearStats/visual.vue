<script lang="ts">
export default {
  name: "VisualTestsGearStatsPage",
};
</script>

<script lang="ts" setup>
import EquipmentGearStats from "@/frontend/components/Equipment/GearStats/index.vue";
import EquipmentStatsCard from "@/frontend/components/StatsCard/Equipment/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { GEAR } from "@/frontend/components/Equipment/GearStats/visual/fixtures";
</script>

<template>
  <div class="gear-stats-visual">
    <section
      v-for="item in GEAR"
      :key="item.id"
      class="gear-stats-visual__item"
      :data-test="`gear-${item.id}`"
    >
      <Heading level="h1" size="xl" mt>{{ item.name }}</Heading>
      <div class="gear-stats-visual__card" :data-test="`card-${item.id}`">
        <EquipmentStatsCard :equipment="item" compact :to="false" />
      </div>
      <EquipmentGearStats :stats="item.stats" />
    </section>
  </div>
</template>

<style lang="scss" scoped>
.gear-stats-visual__item {
  padding-bottom: 32px;
}

// The width the catalogue's tooltip gives the card.
.gear-stats-visual__card {
  max-width: 340px;
}
</style>
