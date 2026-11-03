<script lang="ts">
export default {
  name: "VisualTestsGearStatsPage",
};
</script>

<script lang="ts" setup>
import EquipmentGearStats from "@/frontend/components/Equipment/GearStats/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
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
      <p class="gear-stats-visual__tooltip">
        <CatalogueItemPopover
          :item="{ type: 'Equipment', slug: item.slug, name: item.name }"
          :record="item"
          :link="false"
        />
      </p>
      <EquipmentGearStats :stats="item.stats" />
    </section>
  </div>
</template>

<style lang="scss" scoped>
.gear-stats-visual__item {
  padding-bottom: 32px;
}

// Room below the trigger for the tooltip to open into.
.gear-stats-visual__tooltip {
  margin-bottom: 16px;
}
</style>
