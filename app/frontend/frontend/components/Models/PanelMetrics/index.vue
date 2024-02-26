<template>
  <div>
    <div class="row metrics-block top-metrics metrics-padding">
      <div v-if="model.focus" class="col-6 col-md-4">
        <div class="metrics-label">{{ t("model.focus") }}:</div>
        <div class="metrics-value">
          {{ model.focus }}
        </div>
      </div>
      <div v-if="model.crew.min || model.crew.max" class="col-6 col-md-4">
        <div class="metrics-label">{{ t("model.crew") }}:</div>
        <div class="metrics-value">
          {{ crew }}
        </div>
      </div>
      <div class="col-12 col-md-4">
        <div class="metrics-label">{{ t("model.speed") }}:</div>
        <div v-if="isGroundVehicle" class="metrics-value">
          {{ t("model.max") }}:
          {{ toNumber(model.speeds.groundMaxSpeed, "speed") }}
        </div>
        <div v-else class="metrics-value">
          {{ t("model.scm") }}:
          {{ toNumber(model.speeds.scmSpeed, "speed") }}
          <br />
          {{ t("model.max") }}:
          {{ toNumber(model.speeds.maxSpeed, "speed") }}
        </div>
      </div>
    </div>

    <hr class="dark slim-spacer" />

    <div class="row base-metrics metrics-padding">
      <div class="col-12 metrics-block">
        <div class="row">
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ t("model.length") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.metrics.length, "distance") }}
            </div>
            <div class="metrics-label">{{ t("model.beam") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.metrics.beam, "distance") }}
            </div>
          </div>
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ t("model.height") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.metrics.height, "distance") }}
            </div>
            <div class="metrics-label">{{ t("model.mass") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.metrics.mass, "weight") }}
            </div>
          </div>
          <div class="col-12 col-lg-4">
            <div class="row">
              <div class="col-6 col-lg-12">
                <div class="metrics-label">{{ t("model.cargo") }}:</div>
                <div class="metrics-value">
                  {{ toNumber(model.metrics.cargo, "cargo") }}
                </div>
              </div>
              <div v-if="model.price" class="col-6 col-lg-12">
                <div class="metrics-label">{{ t("model.price") }}:</div>
                <div
                  v-tooltip="toUEC(model.price)"
                  class="metrics-value"
                  v-html="toUEC(model.price)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber, toUEC } = useI18n();

const isGroundVehicle = computed(() => {
  return props.model.classification === "ground";
});

const crew = computed(() => {
  let { min, max } = props.model.crew;

  if (min && min <= 0) {
    min = undefined;
  }

  if (max && max <= 0) {
    max = undefined;
  }

  if (min === max) {
    return toNumber(props.model.crew.min, "people");
  }

  return toNumber([min, max].filter((item) => item).join(" - "), "people");
});
</script>

<script lang="ts">
export default {
  name: "PanelMetrics",
};
</script>
