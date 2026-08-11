<script lang="ts">
export default {
  name: "ModelFlightMetrics",
};
</script>

<script lang="ts" setup>
import { useTransition, TransitionPresets } from "@vueuse/core";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

// Engine power from the pip UI (Hardpoints) — the game's IFCS afterburner ratio
// (engine power above its floor, up to full pips). Only the *boosted* handling
// scales with it; the speeds and base handling are constant game figures, as in
// the IFCS flight model. 1 (full boost) when standalone / no engine family.
const enginePowerRatio = inject<Ref<number | undefined>>(
  "enginePowerRatio",
  ref(1),
);
const boostFactor = computed(() =>
  Math.min(1, Math.max(0, toValue(enginePowerRatio) ?? 1)),
);

const speeds = computed(() => props.model.speeds);
const isGroundVehicle = computed(() => props.model.metrics.isGroundVehicle);

const hasData = computed(() =>
  isGroundVehicle.value
    ? !!speeds.value.groundMaxSpeed
    : !!(speeds.value.scmSpeed || speeds.value.maxSpeed),
);

// Boosted handling interpolates from the base rate up to the rated boosted rate
// by how much boost the engine power supports (0 → base, 1 → rated).
const boosted = (base?: number, rated?: number) =>
  (base ?? 0) + ((rated ?? base ?? 0) - (base ?? 0)) * boostFactor.value;
// toNumber renders 0 as "N/A"; a real zero flight figure should read "0".
const speed = (value: number) =>
  Math.round(value) > 0 ? toNumber(Math.round(value), "speed") : "0";
const rotation = (value: number) =>
  Math.round(value) > 0 ? toNumber(Math.round(value), "rotation") : "0";

const animate = { duration: 400, transition: TransitionPresets.easeOutCubic };
const scmSpeed = useTransition(() => speeds.value.scmSpeed ?? 0, animate);
const boostSpeed = useTransition(
  () => speeds.value.scmSpeedBoosted ?? 0,
  animate,
);
const maxSpeed = useTransition(() => speeds.value.maxSpeed ?? 0, animate);
const groundMax = useTransition(
  () => speeds.value.groundMaxSpeed ?? 0,
  animate,
);
const groundReverse = useTransition(
  () => speeds.value.groundReverseSpeed ?? 0,
  animate,
);

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

// Only surface the boosted rate when the engine power actually lifts it above
// the base handling; at the mandatory floor there's no afterburner to show.
const rotations = computed(() =>
  [
    {
      label: t("model.pitch"),
      base: speeds.value.pitch ?? 0,
      boost: pitchBoost,
    },
    { label: t("model.yaw"), base: speeds.value.yaw ?? 0, boost: yawBoost },
    { label: t("model.roll"), base: speeds.value.roll ?? 0, boost: rollBoost },
  ].map((axis) => ({
    label: axis.label,
    base: axis.base,
    boost: axis.boost.value,
    showBoost: Math.round(axis.boost.value) > Math.round(axis.base),
  })),
);
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
          <div class="metrics-card__tile__value">{{ speed(groundMax) }}</div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("model.groundReverseSpeed") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ speed(groundReverse) }}
          </div>
        </div>
      </template>
      <template v-else>
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">{{ t("model.scmSpeed") }}</div>
          <div class="metrics-card__tile__value">{{ speed(scmSpeed) }}</div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.flight.scm") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.flight.boost") }}
          </div>
          <div class="metrics-card__tile__value">{{ speed(boostSpeed) }}</div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.flight.boostSub") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">{{ t("model.maxSpeed") }}</div>
          <div class="metrics-card__tile__value">{{ speed(maxSpeed) }}</div>
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
            {{ rotation(axis.base) }}
            <span v-if="axis.showBoost" class="flight-rot__boost">
              → {{ rotation(axis.boost) }}
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
