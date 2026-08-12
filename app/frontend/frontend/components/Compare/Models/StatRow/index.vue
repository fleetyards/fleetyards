<script lang="ts">
export default {
  name: "CompareModelsStatRow",
};
</script>

<script lang="ts" setup>
import { markExtremes } from "@/frontend/components/Compare/highlights";
import type { CompareRow } from "@/frontend/components/Compare/types";

type Props = {
  row: CompareRow;
};

const props = defineProps<Props>();

const marks = computed(() =>
  markExtremes(
    props.row.cells.map((cell) => cell.raw),
    props.row.direction,
  ),
);
</script>

<template>
  <div class="compare-grid">
    <div class="compare-cell compare-cell--label">
      {{ row.label }}
    </div>
    <div
      v-for="(cell, index) in row.cells"
      :key="cell.key"
      class="compare-cell compare-cell--value"
      :class="{
        'compare-cell--best': marks[index] === 'best',
        'compare-cell--worst': marks[index] === 'worst',
        'compare-cell--empty': !cell.value,
      }"
    >
      <template v-if="!cell.value">—</template>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-else-if="row.html" v-html="cell.value" />
      <template v-else>
        {{ cell.value }}
        <span v-if="row.unit" class="compare-cell__unit">{{ row.unit }}</span>
      </template>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareGrid";

.compare-cell__unit {
  font-family: "Open Sans", sans-serif;
  font-weight: 600;
  font-size: 10px;
  letter-spacing: 0.08em;
  color: $gray-light;
}

.compare-cell--value::after {
  align-self: center;
}
</style>
