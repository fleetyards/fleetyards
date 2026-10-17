<script lang="ts">
export default {
  name: "VehicleLoadoutModalMetrics",
};
</script>

<script lang="ts" setup>
import type { LoadoutMetric } from "@/frontend/composables/useLoadoutMetrics";

type Props = {
  title: string;
  metrics: LoadoutMetric[];
};

defineProps<Props>();

const width = (ratio: number) => `${Math.min(ratio, 1) * 100}%`;
</script>

<template>
  <section class="loadout-metrics" data-test="vehicle-loadout-metrics">
    <h4 class="metrics-card__section-label">{{ title }}</h4>
    <div
      class="metrics-card__hero metrics-card__hero--grid metrics-card__hero--grid-2"
    >
      <div
        v-for="metric in metrics"
        :key="metric.key"
        class="metrics-card__tile"
        :data-test="`vehicle-loadout-metric-${metric.key}`"
      >
        <div class="metrics-card__tile__label">{{ metric.label }}</div>
        <div class="metrics-card__tile__value">
          {{ metric.value }}
          <span v-if="metric.unit" class="metrics-card__tile__unit">
            {{ metric.unit }}
          </span>
        </div>
        <span
          v-if="metric.deltaLabel"
          class="loadout-metrics__delta"
          :class="`loadout-metrics__delta--${metric.tone}`"
          data-test="vehicle-loadout-metric-delta"
        >
          {{ metric.deltaLabel }}
        </span>
        <span
          v-if="metric.ratio !== undefined"
          class="loadout-metrics__bar"
          :class="{ 'loadout-metrics__bar--over': metric.ratio > 1 }"
          aria-hidden="true"
        >
          <span :style="{ width: width(metric.ratio) }" />
        </span>
      </div>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.loadout-metrics {
  display: flex;
  flex-direction: column;
  gap: 8px;
  container-type: inline-size;

  // Two tiles to a row need room for an uppercase label each; a narrow column
  // stacks them instead of clipping the labels.
  @container (max-width: 320px) {
    .metrics-card__hero--grid-2 {
      grid-template-columns: minmax(0, 1fr);
    }
  }

  .metrics-card__hero {
    margin: 0;
  }

  .metrics-card__section-label {
    margin: 0;
  }

  // The card lets a label take a tile's spare height so values line up when a
  // label wraps; here a change line under one value would push its neighbour's
  // value down instead, so each value sits right under its label.
  .metrics-card__tile__label {
    flex-grow: 0;
  }
}

.loadout-metrics__delta {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;

  &--better {
    color: var(--color-success, #{$success});
  }

  &--worse {
    color: var(--color-danger, #{$danger});
  }
}

// A load against its ceiling, the way the power card fills its segments.
.loadout-metrics__bar {
  display: block;
  height: 4px;
  margin-top: 8px;
  overflow: hidden;
  background: rgba($gray-light, 0.25);
  border-radius: 2px;

  span {
    display: block;
    height: 100%;
    background: var(--color-primary, #428bca);
    border-radius: 2px;
    transition: width $transition-base-speed;
  }

  &--over span {
    background: var(--color-danger, #{$danger});
  }
}
</style>
