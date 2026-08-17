<script lang="ts">
export default {
  name: "ModelCrewMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

defineProps<Props>();

const { t, toNumber } = useI18n();
</script>

<template>
  <MetricsCard :title="t('labels.metrics.crew')">
    <div
      class="metrics-card__hero metrics-card__hero--grid metrics-card__hero--grid-2"
    >
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.minCrew") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(model.crew.min, "people") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.maxCrew") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(model.crew.max, "people") }}
        </div>
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
