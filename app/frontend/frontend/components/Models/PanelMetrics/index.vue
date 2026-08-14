<script lang="ts">
export default {
  name: "PanelMetrics",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber, toUEC } = useI18n();

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

// Ship-matrix speeds are not meaningful, so they are only shown for models whose
// figures come from the game files. isGroundVehicle rather than a classification
// check, matching FlightMetrics: a ground vehicle reports one speed, everything
// else reports two.
const speeds = computed(() => {
  if (!props.model.inGame) {
    return [];
  }

  const { groundMaxSpeed, scmSpeed, maxSpeed } = props.model.speeds;

  if (props.model.metrics.isGroundVehicle) {
    return [{ label: t("model.max"), value: groundMaxSpeed }];
  }

  return [
    { label: t("model.scm"), value: scmSpeed },
    { label: t("model.max"), value: maxSpeed },
  ];
});

const dimensions = computed(() => [
  {
    label: t("model.length"),
    value: toNumber(props.model.metrics.length, "distance"),
  },
  {
    label: t("model.beam"),
    value: toNumber(props.model.metrics.beam, "distance"),
  },
  {
    label: t("model.height"),
    value: toNumber(props.model.metrics.height, "distance"),
  },
  {
    label: t("model.mass"),
    value: toNumber(props.model.metrics.mass, "weight"),
  },
  {
    label: t("model.cargo"),
    value: toNumber(props.model.metrics.cargo, "cargo"),
  },
]);
</script>

<template>
  <div class="panel-metrics">
    <!--
      The same primitives the ship page's metrics cards use, so a card's expanded
      details and the cards further down the page read as one system.

      Rows rather than hero tiles: a card is the narrowest surface in the app, and
      three tiles leave about 110px each even at 520px wide - enough for a figure,
      not for "1 - 6 persons". `__tile__value` is nowrap and clips by design, so
      text values belong in rows, which ellipsise against the full card width.
    -->
    <div class="metrics-card__rows">
      <div v-if="model.focus" class="metrics-card__row">
        <span class="metrics-card__row__label">{{ t("model.focus") }}</span>
        <span class="metrics-card__row__value">{{ model.focus }}</span>
      </div>
      <div v-if="model.crew.min || model.crew.max" class="metrics-card__row">
        <span class="metrics-card__row__label">{{ t("model.crew") }}</span>
        <span class="metrics-card__row__value">{{ crew }}</span>
      </div>
      <div v-for="speed in speeds" :key="speed.label" class="metrics-card__row">
        <span class="metrics-card__row__label">{{ speed.label }}</span>
        <span class="metrics-card__row__value">
          {{ toNumber(speed.value, "speed") }}
        </span>
      </div>
    </div>

    <div class="metrics-card__divider" />

    <div class="metrics-card__rows metrics-card__rows--split">
      <div v-for="row in dimensions" :key="row.label" class="metrics-card__row">
        <span class="metrics-card__row__label">{{ row.label }}</span>
        <span class="metrics-card__row__value">{{ row.value }}</span>
      </div>
      <div v-if="model.price" class="metrics-card__row">
        <span class="metrics-card__row__label">{{ t("model.price") }}</span>
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span
          v-tooltip="toUEC(model.price)"
          class="metrics-card__row__value"
          v-html="toUEC(model.price)"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

/*
 * The blocks used to carry their own 10px 15px through `metrics-padding` and were
 * separated by an `hr.slim-spacer`; the padding is this component's now and the
 * separator is `__divider`, off the same stylesheet as everything else here.
 */
.panel-metrics {
  padding: 14px 16px 16px;
}
</style>
