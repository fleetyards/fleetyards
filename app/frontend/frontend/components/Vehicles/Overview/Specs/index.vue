<script lang="ts">
export default {
  name: "VehicleOverviewSpecs",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Model } from "@/services/fyApi";

type Props = {
  model: Model;
  // Laid over the bottom of the vehicle's picture rather than standing alone.
  overlay?: boolean;
  // The vehicle's own cargo, fitted, in place of the hull's.
  cargoLabel?: string;
};

const props = withDefaults(defineProps<Props>(), {
  overlay: false,
  cargoLabel: undefined,
});

const { t, toNumber } = useI18n();

type Spec = {
  key: string;
  label: string;
  value: string;
};

// The figures a captain looks up most, from the same model data the ship page
// shows; a stat the model has no value for is left out rather than shown as
// "n/a".
const specs = computed(() =>
  (
    [
      {
        key: "length",
        label: t("labels.model.length"),
        value: props.model.metrics.length
          ? toNumber(props.model.metrics.length, "distance")
          : undefined,
      },
      {
        key: "beam",
        label: t("labels.model.beam"),
        value: props.model.metrics.beam
          ? toNumber(props.model.metrics.beam, "distance")
          : undefined,
      },
      {
        key: "crew",
        label: t("labels.model.crew"),
        value: props.model.crew?.label,
      },
      {
        key: "cargo",
        label: t("labels.model.cargo"),
        value:
          props.cargoLabel ??
          (props.model.metrics.cargo
            ? toNumber(props.model.metrics.cargo, "cargo")
            : undefined),
      },
      {
        key: "scmSpeed",
        label: t("labels.model.scmSpeed"),
        value: props.model.speeds?.scmSpeed
          ? toNumber(props.model.speeds.scmSpeed, "speed")
          : undefined,
      },
      {
        key: "productionStatus",
        label: t("labels.vehicleOverview.status"),
        value: props.model.productionStatus
          ? t(`labels.model.productionStatus.${props.model.productionStatus}`)
          : undefined,
      },
    ] as { key: string; label: string; value?: string }[]
  ).filter((spec): spec is Spec => !!spec.value),
);
</script>

<template>
  <dl
    v-if="specs.length"
    class="overview-specs"
    :class="{ 'overview-specs--overlay': overlay }"
    data-test="vehicle-specs"
  >
    <div v-for="spec in specs" :key="spec.key" class="overview-specs__spec">
      <dt>{{ spec.label }}</dt>
      <dd>{{ spec.value }}</dd>
    </div>
  </dl>
</template>

<style lang="scss" scoped>
.overview-specs {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 1px;
  margin: 0 0 20px;
  overflow: hidden;
  border: 1px solid var(--color-edge-soft);
  border-radius: 10px;
  background: var(--color-edge-soft);

  &__spec {
    display: flex;
    flex-direction: column;
    gap: 2px;
    padding: 12px 16px;
    background: var(--color-gray-black);
  }

  dt {
    color: var(--color-text-dim);
    font-size: 0.7rem;
    font-weight: normal;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  dd {
    margin: 0;
    color: #fff;
    font-family: Orbitron, sans-serif;
    font-size: 1.15rem;
  }

  // One row of glass along the picture's lower edge: the hairline gaps stay,
  // the frame goes, and each tile lets the picture through.
  &--overlay {
    margin: 0;
    border: 0;
    border-top: 1px solid var(--color-edge-soft);
    border-radius: 0;
    background: var(--color-edge-faint);

    .overview-specs__spec {
      background: rgb(10 12 14 / 0.72);
      backdrop-filter: blur(6px);
    }
  }
}
</style>
