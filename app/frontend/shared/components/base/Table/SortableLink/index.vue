<script lang="ts">
export default {
  name: "BaseTableHeaderSortableLink",
};
</script>

<script lang="ts" setup generic="T">
import { useTableSorting } from "@/shared/composables/useTableSorting";

type Props = {
  label: string;
  field: string | number | symbol;
  id?: string;
  fallback?: string;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  fallback: undefined,
});

const { currentDirection, sortableLink } = useTableSorting({
  field: props.field,
  fallback: props.fallback,
  id: props.id,
});
</script>

<template>
  <router-link :to="sortableLink" class="base-table-sortable-link">
    {{ props.label }}
    <i v-if="currentDirection === 'desc'" class="fad fa-sort-up" />
    <i v-else-if="currentDirection === 'asc'" class="fad fa-sort-down" />
    <i v-else class="base-table-sortable-link-icon far fa-sort" />
  </router-link>
</template>

<style lang="scss" scoped>
@import "index";
</style>
