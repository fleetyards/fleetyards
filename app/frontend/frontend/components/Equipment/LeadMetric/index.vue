<script lang="ts">
export default {
  name: "EquipmentLeadMetric",
};
</script>

<script lang="ts" setup>
import { useEquipmentStats } from "@/frontend/composables/useEquipmentStats";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment;
  limit?: number;
};

const props = withDefaults(defineProps<Props>(), { limit: 2 });

const stats = useEquipmentStats(() => props.equipment);

const leadStats = computed(() =>
  stats.value.filter((stat) => stat.primary).slice(0, props.limit),
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
@import "@/frontend/components/Components/LeadMetric/index";
</style>
