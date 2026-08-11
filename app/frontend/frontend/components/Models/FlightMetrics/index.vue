<script lang="ts">
export default {
  name: "ModelFlightMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const speeds = computed(() => props.model.speeds);
const isGroundVehicle = computed(() => props.model.metrics.isGroundVehicle);

const hasData = computed(() =>
  isGroundVehicle.value
    ? !!speeds.value.groundMaxSpeed
    : !!(speeds.value.scmSpeed || speeds.value.maxSpeed),
);

// The handling axes (°/s) — only meaningful for spaceflight.
const rotations = computed(() => [
  { label: t("model.pitch"), value: speeds.value.pitch },
  { label: t("model.yaw"), value: speeds.value.yaw },
  { label: t("model.roll"), value: speeds.value.roll },
]);
</script>

<template>
  <MetricsCard
    v-if="hasData"
    :title="t('labels.flight.title')"
    class="flight-panel"
  >
    <div class="metrics-card__hero">
      <template v-if="isGroundVehicle">
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">
            {{ t("model.groundMaxSpeed") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(speeds.groundMaxSpeed, "speed") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("model.groundReverseSpeed") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(speeds.groundReverseSpeed, "speed") }}
          </div>
        </div>
      </template>
      <template v-else>
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">{{ t("model.scmSpeed") }}</div>
          <div class="metrics-card__tile__value">
            {{ toNumber(speeds.scmSpeed, "speed") }}
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.flight.scm") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">{{ t("model.maxSpeed") }}</div>
          <div class="metrics-card__tile__value">
            {{ toNumber(speeds.maxSpeed, "speed") }}
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.flight.nav") }}
          </div>
        </div>
      </template>
    </div>

    <template v-if="!isGroundVehicle">
      <div class="metrics-card__section-label">
        {{ t("labels.flight.maneuverability") }}
      </div>
      <div class="flight-rot">
        <div
          v-for="axis in rotations"
          :key="axis.label"
          class="flight-rot__item"
        >
          <span class="flight-rot__value">
            {{ toNumber(axis.value, "rotation") }}
          </span>
          <span class="flight-rot__label">{{ axis.label }}</span>
        </div>
      </div>
    </template>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">{{ t("labels.flight.hint") }}</span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

.flight-rot {
  display: flex;
  gap: 10px;

  &__item {
    flex: 1 1 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    padding: 10px 6px;
    border: 1px solid rgba($gray-light, 0.16);
    border-radius: 4px;
  }

  &__value {
    font-size: 15px;
    font-weight: 600;
    color: $text-color;
    font-variant-numeric: tabular-nums;
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: $gray;
  }
}
</style>
