<script lang="ts">
export default {
  name: "BaseGrid",
};
</script>

<script lang="ts" setup generic="T">
import Sortable from "sortablejs";
import { useReportListGeometry } from "@/shared/composables/useListGeometry";
import type { ComponentPublicInstance } from "vue";

type Props = {
  records: T[];
  primaryKey: keyof T;
  gridBase?: "2" | "3";
  filterVisible?: boolean;
  // Drag to rearrange. The handle is a selector inside the card, so the card
  // itself stays a link rather than becoming something you cannot click.
  sortable?: boolean;
  sortHandle?: string;
};

const props = withDefaults(defineProps<Props>(), {
  gridBase: "3",
  filterVisible: false,
  sortable: false,
  sortHandle: undefined,
});

// The keys in the order they now sit in. The caller owns the list, so it is the
// one that writes the new order and says what to do if that fails.
// The new order, and the key of the record that was dragged: an order alone
// cannot say which of two swapped neighbours moved.
const emit = defineEmits<{ sort: [keys: string[], moved: string] }>();

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

let sortableInstance: Sortable | null = null;

const initSortable = () => {
  sortableInstance?.destroy();
  sortableInstance = null;

  const container = cells.value?.$el as HTMLElement | undefined;

  if (!props.sortable || !container) {
    return;
  }

  sortableInstance = Sortable.create(container, {
    animation: 150,
    handle: props.sortHandle,
    draggable: ".base-grid__cell",
    onEnd: (event) => {
      const { item, oldIndex, newIndex } = event;

      if (oldIndex === undefined || newIndex === undefined) return;
      if (oldIndex === newIndex) return;

      /*
       * Sortable moves the node itself, and this list is a transition-group --
       * two things writing the same children. So the move is undone here and
       * the order goes out as state instead: the caller re-renders it, and the
       * cards animate between the two positions rather than jumping because
       * Vue's idea of where they are disagrees with the DOM's.
       */
      item.remove();
      container.insertBefore(item, container.children[oldIndex] ?? null);

      const keys = props.records.map((record) => String(primaryValue(record)));
      const [moved] = keys.splice(oldIndex, 1);
      keys.splice(newIndex, 0, moved);

      emit("sort", keys, moved);
    },
  });
};

watch(
  [() => props.sortable, () => props.sortHandle, () => props.records.length],
  () => void nextTick(initSortable),
);

onMounted(() => void nextTick(initSortable));

onUnmounted(() => {
  sortableInstance?.destroy();
  sortableInstance = null;
});
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
