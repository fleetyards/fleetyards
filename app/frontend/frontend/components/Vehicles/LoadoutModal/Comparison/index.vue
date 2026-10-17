<script lang="ts">
export default {
  name: "VehicleLoadoutModalComparison",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import {
  type FittingRow,
  useLoadoutDiff,
} from "@/frontend/composables/useLoadoutDiff";
import { type ModelModule } from "@/services/fyApi";

type Props = {
  hullCargo: number;
  // The rest of the fitting, which stays as it is either way.
  others: ModelModule[];
  // What the slot holds now, and what it would hold instead.
  from?: ModelModule;
  to?: ModelModule;
};

const props = withDefaults(defineProps<Props>(), {
  from: undefined,
  to: undefined,
});

const { t } = useI18n();

const { contents } = useModuleContents();

const { metrics, rows } = useLoadoutDiff();

const fitted = (mod?: ModelModule) =>
  metrics(props.hullCargo, [...props.others, ...(mod ? [mod] : [])]);

// Only what the swap changes: a figure it leaves alone, such as the hull's own
// cargo under a medical module, is already in the ship's figures, and repeated
// here it reads as what each option brings.
const comparison = computed<FittingRow[]>(() =>
  rows(fitted(props.from), fitted(props.to)).filter((row) => row.deltaLabel),
);

// Both bars share a scale, so the longer one is the larger value.
const width = (row: FittingRow, value: number) => {
  const max = Math.max(row.before, row.after);

  return max ? `${(value / max) * 100}%` : "0%";
};

// Nothing swapped: the slot's own module, not a change from it to itself.
const unchanged = computed(() => props.from?.id === props.to?.id);

const name = (mod?: ModelModule) =>
  mod?.name || t("labels.vehicleLoadout.nothingFitted");
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
      v-if="!unchanged && !comparison.length"
      class="loadout-comparison__none"
      data-test="vehicle-loadout-comparison-none"
    >
      {{ t("labels.vehicleLoadout.noFigureChange") }}
    </p>

    <dl v-if="comparison.length" class="loadout-comparison__rows">
      <div
        v-for="row in comparison"
        :key="row.key"
        class="loadout-comparison__row"
        :data-test="`vehicle-loadout-comparison-${row.key}`"
      >
        <dt>
          {{ row.label }}
          <span
            class="loadout-comparison__delta"
            :class="`loadout-comparison__delta--${row.delta?.tone}`"
          >
            {{ row.deltaLabel }}
          </span>
        </dt>
        <dd>
          <span class="loadout-comparison__value">{{ row.value }}</span>
          <span class="loadout-comparison__bars" aria-hidden="true">
            <span
              class="loadout-comparison__bar loadout-comparison__bar--before"
              :style="{ width: width(row, row.before) }"
            />
            <span
              class="loadout-comparison__bar loadout-comparison__bar--after"
              :class="`loadout-comparison__bar--${row.delta?.tone || 'even'}`"
              :style="{ width: width(row, row.after) }"
            />
          </span>
        </dd>
      </div>
    </dl>

    <p v-if="to" class="loadout-comparison__description">
      {{ to.description || contents(to) }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
