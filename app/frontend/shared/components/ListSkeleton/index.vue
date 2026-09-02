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
};

const props = withDefaults(defineProps<Props>(), {
  count: undefined,
});

const geometry = useListGeometry();

// `??`, not `||`: a remembered zero means this list has been seen empty, and
// reserving nothing for it is the right answer rather than a missing one.
const count = computed(() => props.count ?? geometry?.count.value ?? 10);

// Nothing until this list has been seen once, and then exactly what one of its
// rows measured. The floor in the stylesheet only has to carry the first load.
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
      :class="{ 'list-skeleton__item--measured': !!itemHeight }"
      :style="{ height: itemHeight }"
    >
      <span class="skeleton-well list-skeleton__icon" />
      <span class="list-skeleton__lines">
        <span class="skeleton-bar list-skeleton__bar--title" />
        <span class="skeleton-bar list-skeleton__bar--meta" />
      </span>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
@import "index";
</style>
