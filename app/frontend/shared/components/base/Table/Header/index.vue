<script lang="ts">
export default {
  name: "BaseTableHeader",
};
</script>

<script lang="ts" setup generic="T">
import { useI18n } from "@/shared/composables/useI18n";
import SortableLink from "@/shared/components/base/Table/SortableLink/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import TableRow from "@/shared/components/base/Table/Row/index.vue";
import TableCol from "@/shared/components/base/Table/Col/index.vue";

type Props = {
  columns: BaseTableCol<T>[];
  selected: string[];
  colKey: string;
  id?: string;
  selectable?: boolean;
  loading?: boolean;
  emptyVisible?: boolean;
  allSelected?: boolean;
  hasActions?: boolean;
  defaultSort?: string;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  selectable: false,
  loading: false,
  emptyVisible: false,
  allSelected: false,
  hasActions: false,
  defaultSort: undefined,
});

const { t } = useI18n();

const emits = defineEmits<{
  (e: "select-all", selected: boolean): void;
}>();

const handleSelectAll = (selected: boolean) => {
  emits("select-all", selected);
};

const cssClasses = (column: BaseTableCol<T>) => {
  return {
    [`${column.class}`]: column.class,
  };
};
</script>

<template>
  <thead class="base-table-header">
    <TableRow key="header">
      <TableCol v-if="props.selectable" as="th" variant="selection">
        <FormCheckbox
          :disabled="props.loading || props.emptyVisible"
          name="all"
          :model-value="props.allSelected"
          inline
          no-label
          :partial="props.selected.length > 0 && !props.allSelected"
          @update:model-value="handleSelectAll"
        />
      </TableCol>
      <TableCol
        v-for="(column, index) in props.columns"
        :key="`base-table__header-${colKey}-${index}-${column.name}`"
        as="th"
        :class="cssClasses(column)"
        :style="{
          'flex-grow': column.flexGrow,
          width: column.width,
          'min-width': column.minWidth,
        }"
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
      </TableCol>
      <TableCol v-if="props.hasActions" as="th" variant="actions">
        {{ t("labels.actions") }}
      </TableCol>
    </TableRow>
  </thead>
</template>
