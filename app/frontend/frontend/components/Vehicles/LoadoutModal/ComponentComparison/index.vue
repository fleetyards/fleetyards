<script lang="ts">
export default {
  name: "VehicleLoadoutModalComponentComparison",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { FigureChange } from "@/frontend/composables/useComponentFitting";
import type { LoadoutComponentRef } from "@/services/fyApi";

type Props = {
  // What the slot holds now, and what it would hold instead.
  from?: LoadoutComponentRef;
  to?: LoadoutComponentRef;
  rows: FigureChange[];
};

const props = withDefaults(defineProps<Props>(), {
  from: undefined,
  to: undefined,
});

const { t } = useI18n();

const unchanged = computed(() => props.from?.id === props.to?.id);

// Only a swap's changes once there is a swap; the part's own figures before.
const shown = computed(() =>
  unchanged.value ? props.rows : props.rows.filter((row) => row.deltaLabel),
);

// Both bars share a scale, so the longer one is the larger value.
const width = (row: FigureChange, value?: number) => {
  const max = Math.max(row.before ?? 0, row.after ?? 0);

  return max && value ? `${(value / max) * 100}%` : "0%";
};

const name = (component?: LoadoutComponentRef) =>
  component?.name || t("labels.vehicleLoadout.nothingFitted");
</script>

<template>
  <div class="loadout-comparison" data-test="vehicle-loadout-comparison">
    <p
      class="loadout-comparison__swap"
      data-test="vehicle-loadout-comparison-swap"
    >
      <template v-if="!unchanged">
        <span>{{ name(from) }}</span>
        <i class="fa-regular fa-arrow-right" aria-hidden="true" />
      </template>
      <strong>{{ name(to) }}</strong>
    </p>

    <p
      v-if="!unchanged && !shown.length"
      class="loadout-comparison__none"
      data-test="vehicle-loadout-comparison-none"
    >
      {{ t("labels.vehicleLoadout.noFigureChange") }}
    </p>

    <dl v-if="shown.length" class="loadout-comparison__rows">
      <div
        v-for="row in shown"
        :key="row.key"
        class="loadout-comparison__row"
        :data-test="`vehicle-loadout-comparison-${row.key}`"
      >
        <dt>
          {{ row.label }}
          <span
            v-if="row.deltaLabel"
            class="loadout-comparison__delta"
            :class="`loadout-comparison__delta--${row.tone}`"
          >
            {{ row.deltaLabel }}
          </span>
        </dt>
        <dd>
          <span class="loadout-comparison__value">{{ row.value }}</span>
          <span
            v-if="!unchanged"
            class="loadout-comparison__bars"
            aria-hidden="true"
          >
            <span
              class="loadout-comparison__bar loadout-comparison__bar--before"
              :style="{ width: width(row, row.before) }"
            />
            <span
              class="loadout-comparison__bar loadout-comparison__bar--after"
              :class="`loadout-comparison__bar--${row.tone || 'even'}`"
              :style="{ width: width(row, row.after) }"
            />
          </span>
        </dd>
      </div>
    </dl>
  </div>
</template>

<style lang="scss" scoped>
@import "../Comparison/index";
</style>
