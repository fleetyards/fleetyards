<template>
  <div
    class="row metrics-block top-metrics"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div v-if="model.focus" class="col-6 col-md-4">
      <div class="metrics-label">{{ t("model.focus") }}:</div>
      <div class="metrics-value">
        {{ model.focus }}
      </div>
    </div>
    <div v-if="model.minCrew || model.maxCrew" class="col-6 col-md-4">
      <div class="metrics-label">{{ t("model.crew") }}:</div>
      <div class="metrics-value">
        {{ crew }}
      </div>
    </div>
    <div class="col-12 col-md-4">
      <div class="metrics-label">{{ t("model.speed") }}:</div>
      <div class="metrics-value" v-html="speeds" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import type { ModelMinimal } from "@/services/fyApi";
import { useI18n } from "@/embed/composables/useI18n";

type Props = {
  model: ModelMinimal;
  padding?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  padding: false,
});

const { t, toNumber } = useI18n();

const isGroundVehicle = computed(() => props.model.classification === "ground");

const crew = computed(() => {
  const { min: minCrew, max: maxCrew } = props.model.crew;

  if (minCrew === maxCrew && minCrew) {
    return toNumber(minCrew, "people");
  }

  return toNumber(
    [minCrew, maxCrew].filter((item) => item).join(" - "),
    "people"
  );
});

const speeds = computed(() => {
  const speeds = [];

  if (groundSpeeds.value && isGroundVehicle.value) {
    speeds.push(toNumber(groundSpeeds.value, "speed"));
  }

  if (!isGroundVehicle.value) {
    speeds.push(toNumber(airSpeeds.value, "speed"));
  }

  return speeds.join("<br>");
});

const airSpeeds = computed(() => {
  const { scmSpeed, maxSpeed } = props.model.speeds;

  return [scmSpeed, maxSpeed].filter((item) => item).join(" - ");
});

const groundSpeeds = computed(
  () => props.model.speeds.groundMaxSpeed || undefined
);
</script>

<script lang="ts">
export default {
  name: "ModelTopMetrics",
};
</script>
