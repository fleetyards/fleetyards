<script lang="ts">
export default {
  name: "CompareModelsChipsRow",
};
</script>

<script lang="ts" setup>
import type { CompareChipsRow } from "@/frontend/components/Compare/types";

type Props = {
  row: CompareChipsRow;
};

defineProps<Props>();
</script>

<template>
  <div class="compare-grid">
    <div class="compare-cell compare-cell--label">
      {{ row.label }}
    </div>
    <div
      v-for="cell in row.cells"
      :key="cell.key"
      class="compare-cell compare-cell--chips"
      :class="{ 'compare-cell--empty': !cell.chips.length }"
    >
      <template v-if="cell.chips.length">
        <span
          v-for="chip in cell.chips"
          :key="chip.key"
          class="chip"
          :data-type="chip.key"
          :data-negative="chip.negative ? 'true' : undefined"
        >
          <span class="chip__label">{{ chip.label }}</span>
          <span class="chip__value">{{ chip.value }}</span>
        </span>
      </template>
      <template v-else>—</template>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareGrid";

.compare-cell--chips {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 4px;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 13px;
  color: $gray;
  transition: background 0.15s ease;
}

.compare-grid:hover .compare-cell--chips {
  background: rgba(#fff, 0.025);
}

.chip {
  display: inline-flex;
  align-items: baseline;
  gap: 4px;
  padding: 2px 7px;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);
  border-radius: 4px;
  white-space: nowrap;

  &__label {
    font-family: "Open Sans", sans-serif;
    font-size: 10px;
    color: $gray;
  }

  &__value {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 11px;
    font-weight: 700;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &[data-type="energy"] .chip__label {
    color: $primary;
  }

  &[data-type="distortion"] .chip__label {
    color: $cyan;
  }

  &[data-type="thermal"] .chip__label {
    color: $warning;
  }

  &[data-negative="true"] .chip__value {
    color: $danger;
  }
}
</style>
