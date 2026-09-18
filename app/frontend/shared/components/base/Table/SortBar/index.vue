<script lang="ts">
export default {
  name: "BaseTableSortBar",
};
</script>

<script lang="ts" setup generic="T">
import SortChip from "@/shared/components/base/Table/SortBar/Chip/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";

type Props = {
  columns: BaseTableCol<T>[];
  defaultSort?: string;
};

const props = withDefaults(defineProps<Props>(), { defaultSort: undefined });

const { t } = useI18n();

// The same column list the table is built from, so a column that gains or
// loses its sort does so in both places at once -- and the metric columns,
// which appear only when the rows on screen carry the figure, bring their chip
// with them.
//
// A heading is only a sort control while it is on screen: the table scrolls
// sideways on a narrow window and the row it was sorted by scrolls out of
// reach. This line stays put.
const sortable = computed(() =>
  props.columns.filter((column) => column.sortable && column.label),
);
</script>

<template>
  <div v-if="sortable.length" class="base-table-sort-bar">
    <span class="base-table-sort-bar__label">{{ t("actions.sortBy") }}</span>
    <SortChip
      v-for="column in sortable"
      :key="`sort-chip-${column.name}`"
      :label="column.label"
      :field="String(column.attributeKey || column.name)"
      :fallback="props.defaultSort"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
