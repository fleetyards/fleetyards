<script lang="ts">
export default {
  name: "EquipmentLeadMetric",
};
</script>

<script lang="ts" setup>
import { useEquipmentStats } from "@/frontend/composables/useEquipmentStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment;
  limit?: number;
};

const props = withDefaults(defineProps<Props>(), { limit: 4 });

const { t } = useI18n();

const stats = useEquipmentStats(() => props.equipment);

// The headline figures come first in `stats`, so whatever else the item has
// fills the rest of the row. Not volume: it says how much room the item takes,
// not what it does, and an item with nothing else should lead with nothing.
const leadStats = computed(() => {
  const volume = t("labels.equipment.stats.volume");

  return stats.value
    .filter((stat) => stat.label !== volume)
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
@import "@/frontend/components/Components/LeadMetric/index";
</style>
