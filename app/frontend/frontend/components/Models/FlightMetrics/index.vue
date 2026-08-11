<script lang="ts">
export default {
  name: "ModelFlightMetrics",
};
</script>

<script lang="ts" setup>
import { useTransition, TransitionPresets } from "@vueuse/core";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model } from "@/services/fyApi";
import type { FlightMode } from "@/frontend/composables/powerSim";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

// Engine power relative to the default distribution (from Hardpoints): it only
// scales the *boosted* handling — never the speeds or base handling, matching
// erkul. 1 (full boost) when standalone.
const enginePowerRatio = inject<Ref<number | undefined>>(
  "enginePowerRatio",
  ref(1),
);
const boostFactor = computed(() =>
  Math.min(1, Math.max(0, toValue(enginePowerRatio) ?? 1)),
);

// SCM / NAV mode swaps the headline speed (from Hardpoints; SCM standalone).
const flightMode = inject<Ref<FlightMode>>("flightMode", ref("SCM"));
const isNav = computed(() => toValue(flightMode) === "NAV");

const speeds = computed(() => props.model.speeds);
const isGroundVehicle = computed(() => props.model.metrics.isGroundVehicle);

const hasData = computed(() =>
  isGroundVehicle.value
    ? !!speeds.value.groundMaxSpeed
    : !!(speeds.value.scmSpeed || speeds.value.maxSpeed),
);

const speed = (value?: number) => toNumber(Math.round(value ?? 0), "speed");
const rotation = (value: number) => toNumber(Math.round(value), "rotation");

// Boosted handling interpolates from the base rate (no engine power) up to the
// rated boosted rate (full engine power).
const boosted = (base?: number, max?: number) =>
  (base ?? 0) + ((max ?? base ?? 0) - (base ?? 0)) * boostFactor.value;

const rotations = computed(() => [
  {
    label: t("model.pitch"),
    base: speeds.value.pitch,
    max: speeds.value.pitchBoosted,
  },
  {
    label: t("model.yaw"),
    base: speeds.value.yaw,
    max: speeds.value.yawBoosted,
  },
  {
    label: t("model.roll"),
    base: speeds.value.roll,
    max: speeds.value.rollBoosted,
  },
]);

const animate = { duration: 400, transition: TransitionPresets.easeOutCubic };
const pitchBoost = useTransition(
  () => boosted(speeds.value.pitch, speeds.value.pitchBoosted),
  animate,
);
const yawBoost = useTransition(
  () => boosted(speeds.value.yaw, speeds.value.yawBoosted),
  animate,
);
const rollBoost = useTransition(
  () => boosted(speeds.value.roll, speeds.value.rollBoosted),
  animate,
);
const boostAnim = computed<Record<string, number>>(() => ({
  [t("model.pitch")]: pitchBoost.value,
  [t("model.yaw")]: yawBoost.value,
  [t("model.roll")]: rollBoost.value,
}));

const hasReverse = computed(() => !!speeds.value.reverseSpeedBoosted);
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
            {{ speed(speeds.groundMaxSpeed) }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("model.groundReverseSpeed") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ speed(speeds.groundReverseSpeed) }}
          </div>
        </div>
      </template>
      <template v-else>
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">
            {{ isNav ? t("model.maxSpeed") : t("model.scmSpeed") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ speed(isNav ? speeds.maxSpeed : speeds.scmSpeed) }}
          </div>
          <div class="metrics-card__tile__sub">
            {{ isNav ? t("labels.flight.nav") : t("labels.flight.scm") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.flight.boost") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ speed(speeds.scmSpeedBoosted) }}
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.flight.boostSub") }}
          </div>
        </div>
        <div v-if="hasReverse" class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.flight.reverse") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ speed(speeds.reverseSpeedBoosted) }}
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
            {{ rotation(axis.base ?? 0) }}
            <span v-if="axis.max" class="flight-rot__boost">
              → {{ rotation(boostAnim[axis.label]) }}
            </span>
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
    font-size: 14px;
    font-weight: 600;
    color: $text-color;
    font-variant-numeric: tabular-nums;
  }

  &__boost {
    font-size: 11px;
    font-weight: 600;
    color: $primary;
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
