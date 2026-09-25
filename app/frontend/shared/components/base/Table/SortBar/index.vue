<script lang="ts">
export default {
  name: "BaseTableSortBar",
};
</script>

<script lang="ts" setup generic="T">
import SortChip from "@/shared/components/base/Table/SortBar/Chip/index.vue";
import BulkActions from "@/shared/components/base/Table/BulkActions/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { uniq as uniqArray } from "@/shared/utils/Array";
import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";

type Props = {
  columns: BaseTableCol<T>[];
  defaultSort?: string;
  // Puts the list's select-all box in front of the chips and its bulk actions
  // under them, for a list whose rows can be picked. `recordIds` are the rows
  // on screen, which is what the box selects.
  selectable?: boolean;
  recordIds?: string[];
  selectionDisabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  defaultSort: undefined,
  selectable: false,
  recordIds: () => [],
  selectionDisabled: false,
});

const selected = defineModel<string[]>("selected", { default: () => [] });

const slots = defineSlots<{
  "selected-actions"?: (props: { selected: string[] }) => void;
}>();

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

// Rows picked on other pages stay picked: the box only speaks for this page.
const allSelected = computed(
  () =>
    !!props.recordIds.length &&
    props.recordIds.every((id) => selected.value.includes(id)),
);

const onSelectAll = (value?: boolean) => {
  selected.value = value
    ? [...selected.value, ...props.recordIds].filter(uniqArray)
    : selected.value.filter((id) => !props.recordIds.includes(id));
};
</script>

<template>
  <div
    v-if="sortable.length || props.selectable"
    class="base-table-sort-bar-wrapper"
  >
    <div class="base-table-sort-bar">
      <FormCheckbox
        v-if="props.selectable"
        class="base-table-sort-bar__select-all"
        :disabled="props.selectionDisabled || !props.recordIds.length"
        name="all"
        :model-value="allSelected"
        inline
        no-label
        :partial="selected.length > 0 && !allSelected"
        data-test="sort-bar-select-all"
        @update:model-value="onSelectAll"
      />
      <template v-if="sortable.length">
        <span class="base-table-sort-bar__label">{{
          t("actions.sortBy")
        }}</span>
        <SortChip
          v-for="column in sortable"
          :key="`sort-chip-${column.name}`"
          :label="column.label"
          :field="String(column.attributeKey || column.name)"
          :fallback="props.defaultSort"
        />
      </template>
    </div>
    <BulkActions
      v-if="props.selectable"
      :selected="selected"
      @reset="selected = []"
    >
      <slot
        v-if="slots['selected-actions']"
        name="selected-actions"
        :selected="selected"
      />
    </BulkActions>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
