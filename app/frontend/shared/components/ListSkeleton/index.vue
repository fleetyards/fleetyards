<script lang="ts">
export default {
  name: "ListSkeleton",
};
</script>

<script lang="ts" setup>
import { useListGeometry } from "@/shared/composables/useListGeometry";

type Props = {
  // Comes from the list this stands in for when it is inside one.
  count?: number;
  // Whether the rows this waits for carry a selection checkbox. The checkbox
  // takes the row's left inset over from the title, so a placeholder without
  // one stands the icon and both lines 35px left of where they land - which is
  // the whole row sliding sideways as the records arrive.
  selectable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  count: undefined,
  selectable: false,
});

const geometry = useListGeometry();

// `??`, not `||`: a remembered zero means this list has been seen empty, and
// reserving nothing for it is the right answer rather than a missing one.
const count = computed(() => props.count ?? geometry?.count.value ?? 10);

// Nothing until this list has been seen once, and then exactly what one of its
// rows measured - a row whose title runs to two lines is taller than the one
// the stylesheet's arithmetic builds. Unmeasured, the placeholder stands as
// tall as a single-line row on its own.
const itemHeight = computed(() => {
  const remembered = geometry?.heightFor("row");

  return remembered ? `${remembered}px` : undefined;
});
</script>

<template>
  <ul class="list-skeleton" aria-hidden="true" data-test="list-skeleton">
    <li
      v-for="item in count"
      :key="`list-skeleton-${item}`"
      class="list-skeleton__item"
      :class="{ 'list-skeleton__item--selectable': props.selectable }"
      :style="{ height: itemHeight }"
    >
      <span
        v-if="props.selectable"
        class="list-skeleton__checkbox"
        data-test="list-skeleton-checkbox"
      />
      <span class="list-skeleton__select">
        <span class="list-skeleton__icon" />
        <span class="list-skeleton__lines">
          <span class="skeleton-bar skeleton-bar--title" />
          <span class="list-skeleton__meta">
            <span class="skeleton-bar skeleton-bar--type" />
            <span class="skeleton-bar skeleton-bar--time" />
          </span>
        </span>
      </span>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
@import "index";
</style>
