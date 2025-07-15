<script lang="ts">
export default {
  name: "BaseTable",
};
</script>

<script lang="ts" setup generic="T">
import Empty from "@/shared/components/Empty/index.vue";
import { uniq as uniqArray } from "@/shared/utils/Array";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { v4 as uuidv4 } from "uuid";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Loader from "@/shared/components/Loader/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type BaseTableCol } from "./types";
import TableHeader from "./Header/index.vue";
import TableRow from "./Row/index.vue";
import TableCol from "./Col/index.vue";
import BulkActions from "./BulkActions/index.vue";

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
  title: undefined,
  defaultSort: undefined,
  titleLevel: HeadingLevelEnum.H2,
  loading: false,
  inlineLoader: false,
  emptyVisible: false,
  selectable: false,
  selected: () => [],
});

const internalSelected = ref<string[]>([]);

const mobile = useMobile();

const filteredColumns = computed(() => {
  return props.columns.filter((column) => {
    const showMobile = column.mobile === undefined || column.mobile === true;

    return showMobile || !mobile.value;
  });
});

const colKey = ref<string>(uuidv4());

const allSelected = computed(() => {
  if (!props.records.length) {
    return false;
  }

  return props.records
    .map((record) => record[props.primaryKey])
    .every((recordId) => internalSelected.value.includes(recordId as string));
});

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

onMounted(() => {
  colKey.value = uuidv4();
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

const fieldByColumn = (column: BaseTableCol<T>) => {
  return (column.attributeKey || column.name) as keyof T;
};

const primaryValue = (record: T) => {
  return record[props.primaryKey] as string | number;
};

type Slots = {
  title?: () => void;
  empty?: () => void;
  "selected-actions"?: (props: { selected: string[] }) => void;
  actions?: (props: { record: T }) => void;
  [key: `col-${string}`]: (props: { record: T }) => void;
};

const slots = defineSlots<Slots>();

const columnCount = computed(() => {
  return (
    props.columns.length + (slots.actions ? 1 : 0) + (props.selectable ? 1 : 0)
  );
});

const resetSelected = () => {
  internalSelected.value = [];
};
</script>

<template>
  <Panel :id="props.id" class="base-table w-full" :slim="true">
    <PanelHeading v-if="props.title || slots.title" :level="props.titleLevel">
      <slot name="title">{{ props.title }}</slot>
    </PanelHeading>
    <BulkActions :selected="internalSelected" @reset="resetSelected">
      <slot name="selected-actions" :selected="internalSelected" />
    </BulkActions>
    <div class="base-table__outer-wrapper">
      <div class="base-table__wrapper w-full">
        <Loader
          v-if="props.loading && !props.records.length"
          :loading="props.loading"
          class="base-table__loader"
        />
        <table class="base-table__inner">
          <TableHeader
            :id="props.id"
            :col-key="colKey"
            :selected="internalSelected"
            :selectable="props.selectable"
            :loading="props.loading"
            :empty-visible="props.emptyVisible"
            :columns="filteredColumns"
            :has-actions="!!slots.actions"
            :all-selected="allSelected"
            :default-sort="props.defaultSort"
            @select-all="onAllSelectedChange"
          />
          <transition-group
            name="list"
            :class="{
              'base-table__loading': props.loading,
            }"
            tag="tbody"
            :appear="true"
          >
            <TableRow
              v-if="props.emptyVisible && !props.loading"
              key="empty-row"
            >
              <TableCol :colspan="columnCount" variant="empty">
                <slot name="empty">
                  <Empty />
                </slot>
              </TableCol>
            </TableRow>
            <TableRow
              v-for="record in props.records"
              v-else
              :id="String(primaryValue(record))"
              :key="primaryValue(record)"
            >
              <TableCol v-if="props.selectable" variant="selection">
                <FormCheckbox
                  v-model="internalSelected"
                  name="item"
                  no-label
                  inline
                  :checkbox-value="primaryValue(record)"
                />
              </TableCol>
              <TableCol
                v-for="column in filteredColumns"
                :key="`base-table__item-${colKey}-${column.name}`"
                :alignment="column.alignment"
                :class="{
                  [`${column.class}`]: !!column.class,
                }"
                :style="{
                  'flex-grow': column.flexGrow,
                  width: column.width,
                  'min-width': column.minWidth,
                }"
              >
                <slot :record="record" :name="`col-${column.name}`">
                  {{ record[fieldByColumn(column)] }}
                </slot>
              </TableCol>
              <TableCol v-if="slots.actions" variant="actions">
                <slot :record="record" name="actions" />
              </TableCol>
            </TableRow>
          </transition-group>
        </table>
      </div>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
