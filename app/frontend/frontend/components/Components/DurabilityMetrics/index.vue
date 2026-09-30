<script lang="ts">
export default {
  name: "ComponentDurabilityMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { ComponentDurability } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentDurability } from "@/frontend/composables/useComponentDurability";

type Props = {
  durability?: ComponentDurability | null;
};

const props = defineProps<Props>();

const { t } = useI18n();

const groups = useComponentDurability(() => props.durability);
</script>

<template>
  <MetricsCard
    v-for="group in groups"
    :key="group.key"
    :title="t(`headlines.component.${group.key}`)"
    variant="slim"
    :data-test="`durability-${group.key}`"
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
