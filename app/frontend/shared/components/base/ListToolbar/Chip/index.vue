<script lang="ts">
export default {
  name: "BaseListToolbarChip",
};
</script>

<script lang="ts" setup>
import {
  nextSort,
  sortDirectionOf,
  useTableSorting,
} from "@/shared/composables/useTableSorting";

type Props = {
  label: string;
  field: string;
  fallback?: string;
  // Keeps the sort in `sort` instead of the URL, for a list that is not the
  // page's own -- one inside a modal would otherwise re-sort the page under it.
  local?: boolean;
  sort?: string;
};

const props = withDefaults(defineProps<Props>(), {
  fallback: undefined,
  local: false,
  sort: undefined,
});

const emit = defineEmits<{
  "update:sort": [sort: string | undefined];
}>();

// The same composable the column headings use, so the two controls cannot
// disagree: both read and write `route.query.s`, and pressing either cycles
// none, ascending, descending in the same order -- the default's own field
// toggles between its two directions.
const { currentDirection, sortableLink, resetLink } = useTableSorting({
  field: props.field,
  fallback: () => props.fallback,
});

const route = useRoute();
const router = useRouter();

const direction = computed(() =>
  props.local
    ? sortDirectionOf(props.sort, props.field, props.fallback)
    : currentDirection.value,
);

const onLocalClick = () =>
  emit("update:sort", nextSort(props.sort, props.field, props.fallback));

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
  <button
    v-if="local"
    type="button"
    class="base-list-toolbar-chip"
    :class="{ 'base-list-toolbar-chip--active': !!direction }"
    :aria-pressed="!!direction"
    @click="onLocalClick"
  >
    {{ props.label }}
    <i v-if="direction === 'desc'" class="fa-duotone fa-sort-up" />
    <i v-else-if="direction === 'asc'" class="fa-duotone fa-sort-down" />
  </button>
  <router-link
    v-else
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
