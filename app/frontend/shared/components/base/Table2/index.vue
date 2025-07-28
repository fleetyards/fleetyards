<script lang="ts">
export default {
  name: "BaseTable2",
};
</script>

<script lang="ts" setup generic="T">
import Empty from "@/shared/components/Empty/index.vue";
import { v4 as uuidv4 } from "uuid";
import { uniq as uniqArray } from "@/shared/utils/Array";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Loader from "@/shared/components/Loader/index.vue";
import BulkActions from "@/shared/components/base/Table/BulkActions/index.vue";
import TableHeader from "./Header/index.vue";
import TableRow from "./Row/index.vue";
import TableCell from "./Cell/index.vue";
import { type BaseTableCol, type BaseTableItem } from "./types";

type Props = {
  records: T[];
  columns: BaseTableCol<T>[];
  primaryKey: keyof T;
  id?: string;
  defaultSort?: string;
  title?: string;
  titleLevel?: HeadingLevelEnum;
  loading?: boolean;
  inlineLoader?: boolean;
  emptyVisible?: boolean;
  selectable?: boolean;
  selected?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  records: () => [],
  defaultSort: undefined,
  selectable: false,
  selected: () => [],
  loading: false,
  emptyVisible: false,
  title: undefined,
  titleLevel: HeadingLevelEnum.H2,
});

const internalSelected = ref<string[]>([]);

const primaryValue = (record: T) => {
  return record[props.primaryKey] as string | number;
};

watch(
  () => props.selected,
  () => {
    internalSelected.value = props.selected;
  },
);

const emit = defineEmits(["selected-change"]);

watch(
  () => internalSelected.value,
  () => {
    emit("selected-change", internalSelected.value);
  },
);

const colKey = ref<string>(uuidv4());

onMounted(() => {
  colKey.value = uuidv4();
});

const gridColumns = computed(() => {
  const grid = [];

  if (props.selectable) {
    grid.push("60px");
  }

  props.columns.forEach((column) => {
    grid.push(column.width || "1fr");
  });

  if (slots.actions) {
    grid.push("210px");
  }

  return grid.join(" ");
});

type Slots = {
  title?: () => void;
  empty?: () => void;
  "selected-actions"?: (props: { selected: string[] }) => void;
  actions?: (props: { record: T | BaseTableItem }) => void;
  [key: `col-${string}`]: (props: { record: T | BaseTableItem }) => void;
};

const slots = defineSlots<Slots>();

const allSelected = computed(() => {
  if (!props.records.length) {
    return false;
  }

  return props.records
    .map((record) => record[props.primaryKey])
    .every((recordId) => internalSelected.value.includes(recordId as string));
});

const onAllSelectedChange = (value?: boolean) => {
  if (value) {
    internalSelected.value = [
      ...internalSelected.value,
      ...props.records.map((record) => record[props.primaryKey] as string),
    ].filter(uniqArray);
  } else {
    internalSelected.value = [...internalSelected.value].filter(
      (selected) =>
        !props.records
          .map((record) => record[props.primaryKey] as string)
          .includes(selected),
    );
  }
};

const resetSelected = () => {
  internalSelected.value = [];
};
</script>

<template>
  <Panel :id="props.id" class="base-table w-full" slim>
    <PanelHeading v-if="props.title || slots.title" :level="props.titleLevel">
      <slot name="title">{{ props.title }}</slot>
    </PanelHeading>
    <BulkActions :selected="internalSelected" @reset="resetSelected">
      <slot name="selected-actions" :selected="internalSelected" />
    </BulkActions>
    <div class="base-table-container" role="table" aria-label="Table">
      <TableHeader
        :id="props.id"
        :grid-columns="gridColumns"
        :col-key="colKey"
        :selected="internalSelected"
        :selectable="props.selectable"
        :loading="props.loading"
        :empty-visible="props.emptyVisible"
        :columns="columns"
        :has-actions="!!slots.actions"
        :all-selected="allSelected"
        :default-sort="props.defaultSort"
        @select-all="onAllSelectedChange"
      />
      <Loader
        v-if="props.loading && !props.records.length"
        :loading="props.loading"
        class="base-table__loader"
      />
      <transition-group name="list" :appear="true">
        <TableRow
          v-if="props.emptyVisible && !props.loading"
          key="empty-row"
          empty
        >
          <slot name="empty">
            <Empty />
          </slot>
        </TableRow>
        <TableRow
          v-for="record in records"
          v-else
          :key="`${record[primaryKey]}`"
          :grid-columns="gridColumns"
        >
          <TableCell v-if="selectable" key="selectable">
            <FormCheckbox
              v-model="internalSelected"
              name="item"
              no-label
              inline
              :checkbox-value="primaryValue(record)"
            />
          </TableCell>
          <TableCell v-for="column in columns" :key="column.name">
            <slot :name="`col-${column.name}`" :record="record">
              <template v-if="column.attributeKey">
                {{ record[column.attributeKey] }}
              </template>
            </slot>
          </TableCell>
          <TableCell v-if="slots.actions" key="actions" alignment="right">
            <slot :record="record" name="actions" />
          </TableCell>
        </TableRow>
      </transition-group>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
