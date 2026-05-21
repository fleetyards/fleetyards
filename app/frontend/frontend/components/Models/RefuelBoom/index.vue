<script lang="ts">
export default {
  name: "ModelRefuelBoom",
};
</script>

<script lang="ts" setup>
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
  <div
    v-if="boom"
    class="row refuel-boom metrics-padding"
    data-test="refuel-boom"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.model.refuelBoom") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div v-if="armLabel" class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.model.refuelBoomArm") }}:
          </div>
          <div class="metrics-value">{{ armLabel }}</div>
        </div>
        <div v-if="nozzleLabel" class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.model.refuelBoomNozzle") }}:
          </div>
          <div class="metrics-value">{{ nozzleLabel }}</div>
        </div>
        <div v-if="boom.captureRadius != null" class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.hardpoint.refuelBoom.captureRadius") }}:
          </div>
          <div class="metrics-value">
            {{ toNumber(boom.captureRadius, "integer") }} m
          </div>
        </div>
      </div>
      <div
        v-if="boom.fuelFlowRate != null || boom.quantumFuelFlowRate != null"
        class="row"
      >
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div class="row">
        <div v-if="boom.fuelFlowRate != null" class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.hardpoint.refuelBoom.fuelFlowRate") }}:
          </div>
          <div class="metrics-value">
            {{ toNumber(boom.fuelFlowRate, "cargo") }}/s
          </div>
        </div>
        <div v-if="boom.quantumFuelFlowRate != null" class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.hardpoint.refuelBoom.quantumFuelFlowRate") }}:
          </div>
          <div class="metrics-value">
            {{ toNumber(boom.quantumFuelFlowRate, "cargo") }}/s
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
