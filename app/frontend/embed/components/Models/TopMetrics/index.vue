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
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  model: Model;
  padding?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  padding: false,
});

const { t, toNumber } = useI18n();

const isGroundVehicle = computed(() => props.model.classification === "ground");

const crew = computed(() => {
  let minCrew: number | null = null;
  minCrew = props.model.minCrew;
  let maxCrew: number | null = null;
  maxCrew = props.model.maxCrew;

  if (minCrew && minCrew <= 0) {
    minCrew = null;
  }

  if (maxCrew && maxCrew <= 0) {
    maxCrew = null;
  }

  if (minCrew === maxCrew) {
    return toNumber(props.model.minCrew, "people");
  }

  return toNumber(
    [minCrew, maxCrew].filter((item) => item).join(" - "),
    "people",
  );
});

const speeds = computed(() => {
  const speeds = [];

  if (groundSpeeds.value || isGroundVehicle.value) {
    speeds.push(toNumber(groundSpeeds.value, "speed"));
  }

  if (!isGroundVehicle.value) {
    speeds.push(toNumber(airSpeeds.value, "speed"));
  }

  return speeds.join("<br>");
});

const airSpeeds = computed(() => {
  let scmSpeed: number | null = null;
  scmSpeed = props.model.scmSpeed;
  let afterburnerSpeed: number | null = null;
  afterburnerSpeed = props.model.afterburnerSpeed;

  if (scmSpeed && scmSpeed <= 0) {
    scmSpeed = null;
  }

  if (afterburnerSpeed && afterburnerSpeed <= 0) {
    afterburnerSpeed = null;
  }

  return [scmSpeed, afterburnerSpeed].filter((item) => item).join(" - ");
});

const groundSpeeds = computed(() => {
  let groundSpeed: number | null = null;
  groundSpeed = props.model.groundSpeed;
  let afterburnerGroundSpeed: number | null = null;
  afterburnerGroundSpeed = props.model.afterburnerGroundSpeed;

  if (groundSpeed && groundSpeed <= 0) {
    groundSpeed = null;
  }

  if (afterburnerGroundSpeed && afterburnerGroundSpeed <= 0) {
    afterburnerGroundSpeed = null;
  }

  return [groundSpeed, afterburnerGroundSpeed]
    .filter((item) => item)
    .join(" - ");
});
</script>

<script lang="ts">
export default {
  name: "ModelTopMetrics",
};
</script>
