<script lang="ts">
export default {
  name: "BaseListToolbarChip",
};
</script>

<script lang="ts" setup>
import { useTableSorting } from "@/shared/composables/useTableSorting";

type Props = {
  label: string;
  field: string;
  fallback?: string;
};

const props = withDefaults(defineProps<Props>(), { fallback: undefined });

// The same composable the column headings use, so the two controls cannot
// disagree: both read and write `route.query.s`, and pressing either cycles
// none, ascending, descending in the same order.
const { currentDirection, sortableLink, resetLink } = useTableSorting({
  field: props.field,
  fallback: () => props.fallback,
});

const route = useRoute();
const router = useRouter();

// A shortcut to the third press. Only the sort the URL names has one; a chip
// lit by the default, or not lit at all, keeps the browser's own menu.
const resettable = computed(
  () => ((route.query.s as string) || "").split(" ")[0] === props.field,
);

const onContextMenu = (event: MouseEvent) => {
  if (!resettable.value) {
    return;
  }

  event.preventDefault();
  void router.push(resetLink.value);
};
</script>

<template>
  <router-link
    :to="sortableLink"
    class="base-list-toolbar-chip"
    :class="{ 'base-list-toolbar-chip--active': !!currentDirection }"
    @contextmenu="onContextMenu"
  >
    {{ props.label }}
    <!-- Matching `SortableLink`'s own arrows rather than picking a pair: the
         two controls sit on the same page and would otherwise disagree about
         which way up "descending" points. -->
    <i v-if="currentDirection === 'desc'" class="fa-duotone fa-sort-up" />
    <i v-else-if="currentDirection === 'asc'" class="fa-duotone fa-sort-down" />
  </router-link>
</template>

<style lang="scss" scoped>
@import "index";
</style>
