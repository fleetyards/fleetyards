<script lang="ts">
export default {
  name: "ModelMetricRows",
};
</script>

<script lang="ts" setup>
import type { MetricRowGroup } from "@/shared/composables/useModelMetricRows";

type Props = {
  groups: MetricRowGroup[];
};

const props = defineProps<Props>();

// A group with nothing in it is not a group. A model with no focus, no crew and
// ship-matrix speeds has an empty summary, and rendering it left an empty box
// with a divider under it.
const visibleGroups = computed(() =>
  props.groups.filter((group) => group.rows.length > 0),
);
</script>

<template>
  <!--
    The same primitives the ship page's metrics cards use, so a card's expanded
    details and the cards further down the page read as one system.

    Rows rather than hero tiles: a card is the narrowest surface in the app, and
    three tiles leave about 110px each even at 520px wide - enough for a figure,
    not for "1 - 6 persons". `__tile__value` is nowrap and clips by design, so
    text values belong in rows, which ellipsise against the full card width.
  -->
  <template v-for="(group, index) in visibleGroups" :key="index">
    <div v-if="index > 0" class="metrics-card__divider" />
    <div
      class="metrics-card__rows"
      :class="{ 'metrics-card__rows--split': group.split }"
    >
      <div v-for="row in group.rows" :key="row.label" class="metrics-card__row">
        <span class="metrics-card__row__label">{{ row.label }}</span>
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span
          v-if="row.html"
          v-tooltip="row.value"
          class="metrics-card__row__value"
          v-html="row.value"
        />
        <span v-else class="metrics-card__row__value">{{ row.value }}</span>
      </div>
    </div>
  </template>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
