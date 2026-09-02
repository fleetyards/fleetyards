<script lang="ts">
export default {
  name: "BaseGrid",
};
</script>

<script lang="ts" setup generic="T">
import { useReportListGeometry } from "@/shared/composables/useListGeometry";
import type { ComponentPublicInstance } from "vue";

type Props = {
  records: T[];
  primaryKey: keyof T;
  gridBase?: "2" | "3";
  filterVisible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  gridBase: "3",
  filterVisible: false,
});

const gridClasses = computed(() => {
  if (props.gridBase === "3") {
    return `col-12 col-md-6 col-lg-4 ${gridClassesWithFilter.value}`;
  }

  return `col-12 col-lg-6 ${gridClassesWithFilter.value}`;
});

const gridClassesWithFilter = computed(() => {
  if (props.gridBase === "3") {
    if (props.filterVisible) {
      return "col-xxl-3 col-3xl-2dot4";
    }
    return "col-xl-3 col-xxl-2dot4 col-3xl-2";
  }

  if (props.filterVisible) {
    return "col-xxl-3 col-3xl-2dot4";
  }

  return "col-xl-3 col-xxl-2dot4 col-3xl-2";
});

const cssClasses = computed(() => {
  return `fade-list-item base-grid__cell ${gridClasses.value}`;
});

const primaryValue = (record: T) => {
  return record[props.primaryKey] as string | number;
};

// The transition group is a component, so the row it renders is reached through
// its root rather than by the ref itself.
const cells = ref<ComponentPublicInstance>();

// What the placeholder cards of the next load stand as tall as. A card's height
// is its content's - a longer name, an open details panel, the column count at
// this width - so the card itself is the only thing that knows.
const { report } = useReportListGeometry("card", cells, {
  ready: () => !!props.records.length,
  // The card, not the cell around it: a cell carries the card's outer margin as
  // well, and a placeholder given that height would stand taller than the card
  // it stands in for by exactly that margin.
  pick: (host) =>
    host.querySelector<HTMLElement>(".base-grid__cell")?.firstElementChild,
});

// The filter panel takes a column away from the grid, which makes every card in
// it narrower and most of them taller.
watch(() => props.filterVisible, report);
</script>

<template>
  <transition-group
    ref="cells"
    name="fade-list"
    class="row"
    tag="div"
    :appear="true"
  >
    <div
      v-for="(record, index) in records"
      :key="primaryValue(record)"
      :class="cssClasses"
    >
      <slot :record="record" :index="index" />
    </div>
  </transition-group>
</template>

<style lang="scss" scoped>
/*
 * Equal-height cards are the grid's job, not the card's. A percentage height on
 * the panel itself resolves against this cell - including any sibling above it -
 * so a card with a heading beside it overflowed. Stretching from here needs no
 * percentage: the cell is already stretched to the tallest in its flex line, and
 * the card grows to fill what is left.
 */
.base-grid__cell {
  display: flex;
  flex-direction: column;
}

/* 1 0 auto, not 1: grow to fill the cell, but never shrink below the content's
   own height. `flex: 1` sets a zero basis, which relies on min-height:auto alone
   to stop a tall card being squeezed. */
.base-grid__cell > :deep(*) {
  flex: 1 0 auto;
}
</style>
