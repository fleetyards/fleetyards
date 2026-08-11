<script lang="ts">
export default {
  name: "ModelRefuelBoom",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber } = useI18n();

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const boom = computed(() => props.model.refuelBoom);

const armLabel = computed(() => {
  if (!boom.value?.armName) return null;
  if (boom.value.armSize) {
    return `${boom.value.armName} (S${boom.value.armSize})`;
  }
  return boom.value.armName;
});

const nozzleLabel = computed(() => {
  if (!boom.value?.nozzleName) return null;
  if (boom.value.nozzleSize) {
    return `${boom.value.nozzleName} (S${boom.value.nozzleSize})`;
  }
  return boom.value.nozzleName;
});
</script>

<template>
  <MetricsCard
    v-if="boom"
    :title="t('labels.model.refuelBoom')"
    class="refuel-boom-panel"
    data-test="refuel-boom"
  >
    <div class="metrics-card__hero">
      <div
        v-if="boom.fuelFlowRate != null"
        class="metrics-card__tile metrics-card__tile--primary"
      >
        <div class="metrics-card__tile__label">
          {{ t("labels.hardpoint.refuelBoom.fuelFlowRate") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ toNumber(boom.fuelFlowRate, "cargo") }}
          <span class="metrics-card__tile__unit">/s</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.refuelBoom.fuelFlowSub") }}
        </div>
      </div>
      <div v-if="boom.quantumFuelFlowRate != null" class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.hardpoint.refuelBoom.quantumFuelFlowRate") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ toNumber(boom.quantumFuelFlowRate, "cargo") }}
          <span class="metrics-card__tile__unit">/s</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.refuelBoom.quantumFlowSub") }}
        </div>
      </div>
      <div v-if="boom.captureRadius != null" class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.hardpoint.refuelBoom.captureRadius") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ toNumber(boom.captureRadius, "integer") }}
          <span class="metrics-card__tile__unit">m</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.refuelBoom.captureRadiusSub") }}
        </div>
      </div>
    </div>

    <template v-if="armLabel || nozzleLabel">
      <div class="metrics-card__section-label">
        {{ t("labels.refuelBoom.equipment") }}
      </div>
      <div v-if="armLabel" class="metrics-card__aux">
        <span class="metrics-card__aux-label">
          {{ t("labels.model.refuelBoomArm") }}
        </span>
        <span class="metrics-card__aux-value">{{ armLabel }}</span>
      </div>
      <div v-if="nozzleLabel" class="metrics-card__aux">
        <span class="metrics-card__aux-label">
          {{ t("labels.model.refuelBoomNozzle") }}
        </span>
        <span class="metrics-card__aux-value">{{ nozzleLabel }}</span>
      </div>
    </template>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">{{ t("labels.refuelBoom.hint") }}</span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

// The equipment rows carry component names rather than figures, so they wrap
// instead of holding the baseline row the numeric aux stats use.
.metrics-card__aux {
  margin-bottom: 10px;
  flex-wrap: wrap;
}
</style>
