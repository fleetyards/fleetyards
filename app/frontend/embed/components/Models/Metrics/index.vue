<script lang="ts">
export default {
  name: "EmbedModelMetrics",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/embed/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber, toUEC } = useI18n();

const isGroundVehicle = computed(() => props.model.classification === "ground");

const crew = computed(() => {
  const { min: minCrew, max: maxCrew } = props.model.crew;

  if (minCrew === maxCrew && minCrew) {
    return toNumber(minCrew, "people");
  }

  return toNumber(
    [minCrew, maxCrew].filter((item) => item).join(" - "),
    "people",
  );
});

const speeds = computed(() => {
  if (isGroundVehicle.value) {
    return `${t("model.max")}: ${toNumber(props.model.speeds.groundMaxSpeed, "speed")}`;
  }

  return `${t("model.scm")}: ${toNumber(props.model.speeds.scmSpeed, "speed")}<br>${t("model.max")}: ${toNumber(props.model.speeds.maxSpeed, "speed")}`;
});
</script>

<template>
  <div class="embed-model-metrics">
    <div class="embed-metrics-grid metrics-block top-metrics metrics-padding">
      <div>
        <template v-if="model.focus">
          <div class="metrics-label">{{ t("model.focus") }}:</div>
          <div class="metrics-value">
            {{ model.focus }}
          </div>
        </template>
        <div class="metrics-label">{{ t("model.speed") }}:</div>
        <div class="metrics-value" v-html="speeds" />
      </div>
      <div v-if="model.crew.min || model.crew.max">
        <div class="metrics-label">{{ t("model.crew") }}:</div>
        <div class="metrics-value">
          {{ crew }}
        </div>
      </div>
    </div>

    <hr class="dark slim-spacer" />

    <div class="embed-metrics-grid metrics-block metrics-padding">
      <div>
        <div class="metrics-label">{{ t("model.length") }}:</div>
        <div class="metrics-value">
          {{ toNumber(model.metrics.length, "distance") }}
        </div>
        <div class="metrics-label">{{ t("model.beam") }}:</div>
        <div class="metrics-value">
          {{ toNumber(model.metrics.beam, "distance") }}
        </div>
        <div class="metrics-label">{{ t("model.cargo") }}:</div>
        <div class="metrics-value">
          {{ toNumber(model.metrics.cargo, "cargo") }}
        </div>
      </div>
      <div>
        <div class="metrics-label">{{ t("model.height") }}:</div>
        <div class="metrics-value">
          {{ toNumber(model.metrics.height, "distance") }}
        </div>
        <div class="metrics-label">{{ t("model.mass") }}:</div>
        <div class="metrics-value">
          {{ toNumber(model.metrics.mass, "weight") }}
        </div>
        <template v-if="model.price">
          <div class="metrics-label">{{ t("model.price") }}:</div>
          <span class="metrics-value" v-html="toUEC(model.price)" />
        </template>
      </div>
    </div>
  </div>
</template>
