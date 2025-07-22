<script lang="ts">
export default {
  name: "BaseTableHeader",
};
</script>

<script lang="ts" setup generic="T">
import { useI18n } from "@/shared/composables/useI18n";
import SortableLink from "@/shared/components/base/Table/SortableLink/index.vue";
import TableCell from "@/shared/components/base/Table2/Cell/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table2/types";

type Props = {
  columns: BaseTableCol<T>[];
  id?: string;
  gridColumns?: string;
  selected?: string[];
  loading?: boolean;
  emptyVisible?: boolean;
  selectable?: boolean;
  allSelected?: boolean;
  defaultSort?: string;
  hasActions?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  gridColumns: "",
  selectable: false,
  selected: () => [],
  allSelected: false,
  defaultSort: undefined,
  loading: false,
  emptyVisible: false,
  hasActions: false,
});

const { t } = useI18n();

const emits = defineEmits<{
  (e: "select-all", selected: boolean): void;
}>();

const handleSelectAll = (selected: boolean) => {
  emits("select-all", selected);
};
</script>

<template>
  <div
    class="base-table-header"
    role="row"
    :style="{ gridTemplateColumns: gridColumns }"
  >
    <TableCell
      v-if="props.selectable"
      header
      variant="selection"
      role="columnheader"
    >
      <FormCheckbox
        name="all"
        :disabled="props.loading || props.emptyVisible"
        :model-value="props.allSelected"
        inline
        no-label
        :partial="props.selected.length > 0 && !props.allSelected"
        @update:model-value="handleSelectAll"
      />
    </TableCell>
    <TableCell
      v-for="column in columns"
      :key="column.name"
      header
      role="columnheader"
    >
      <SortableLink
        v-if="column.sortable"
        :id="props.id"
        :label="column.label"
        :field="column.attributeKey || column.name"
        :fallback="props.defaultSort"
      />
      <span v-else>
        {{ column.label }}
      </span>
    </TableCell>
    <TableCell v-if="hasActions" alignment="right" header>
      {{ t("labels.actions") }}
    </TableCell>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
