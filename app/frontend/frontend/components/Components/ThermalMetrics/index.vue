<script lang="ts">
export default {
  name: "ComponentThermalMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentThermal } from "@/frontend/composables/useComponentThermal";
import type { Component } from "@/services/fyApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t } = useI18n();

const thermal = useComponentThermal(() => props.component);
</script>

<template>
  <MetricsCard
    v-if="thermal.temperature.length"
    :title="t('headlines.component.temperature')"
    variant="slim"
    data-test="component-temperature"
  >
    <div class="metrics-card__rows">
      <div
        v-for="row in thermal.temperature"
        :key="row.label"
        class="metrics-card__row"
      >
        <span class="metrics-card__row__label">{{ row.label }}</span>
        <span class="metrics-card__row__value">{{ row.value }}</span>
      </div>
    </div>
  </MetricsCard>

  <MetricsCard
    v-if="thermal.misfire.length"
    :title="t('headlines.component.misfire')"
    variant="slim"
    data-test="component-misfire"
  >
    <div class="metrics-card__rows">
      <div
        v-for="row in thermal.misfire"
        :key="row.label"
        class="metrics-card__row"
      >
        <span class="metrics-card__row__label">{{ row.label }}</span>
        <span class="metrics-card__row__value">{{ row.value }}</span>
      </div>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">
        {{ t("labels.component.misfire.hint") }}
      </span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
