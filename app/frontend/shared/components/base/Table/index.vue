<script lang="ts">
import { type BaseTableCol } from "./types";

export default {
  name: "BaseTable",
};

export type { BaseTableCol };
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
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { useMobile } from "@/shared/composables/useMobile";
import {
  useListGeometry,
  useReportListGeometry,
} from "@/shared/composables/useListGeometry";
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
  asyncStatus?: AsyncStatus;
  inlineLoader?: boolean;
  emptyVisible?: boolean;
  selectable?: boolean;
  selected?: string[];
  rowClickable?: boolean;
  rowDisabled?: (record: T) => boolean;
  fillHeight?: boolean;
  admin?: boolean;
  // Placeholder rows to hold the table open with while it waits for its first
  // records. A table inside a list takes the count from the list instead, so
  // this is only for one standing on its own.
  skeletonRows?: number;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  title: undefined,
  defaultSort: undefined,
  titleLevel: HeadingLevelEnum.H2,
  loading: false,
  asyncStatus: undefined,
  inlineLoader: false,
  emptyVisible: false,
  selectable: false,
  selected: () => [],
  rowClickable: false,
  rowDisabled: undefined,
  fillHeight: false,
  admin: false,
  skeletonRows: undefined,
});

const isLoading = computed(() => {
  if (props.asyncStatus) {
    return (
      props.asyncStatus.isLoading.value || props.asyncStatus.isFetching.value
    );
  }

  return props.loading;
});

const internalSelected = ref<string[]>([]);

const mobile = useMobile();

// A list frames the table with its own page size and with what a row of this
// very table measured last time; a table standing on its own is told.
const geometry = useListGeometry();

const skeletonRowCount = computed(
  () => props.skeletonRows ?? geometry?.count.value ?? 0,
);

// Only for the first load. A refetch keeps the records it already has on
// screen, and they hold the table open better than placeholders would.
const skeletonVisible = computed(
  () => !!skeletonRowCount.value && isLoading.value && !props.records.length,
);

// Held back only where the list around the table is already showing one over
// the placeholder rows. A table left to load on its own - a list that hides the
// outer spinner in favour of this one, or a table with no list at all - keeps
// it.
const ownLoaderVisible = computed(() => {
  if (!isLoading.value || props.records.length) {
    return false;
  }

  return !(skeletonVisible.value && !!geometry?.spinnerVisible.value);
});

// Nothing until this table has been seen once, and then exactly what it was:
// the fallbacks below - a line of text, the control height where the row has
// buttons - only have to carry the very first load.
const skeletonRowHeight = computed(() => {
  const remembered = geometry?.heightFor("row");

  return remembered ? `${remembered}px` : undefined;
});

const inner = ref<HTMLElement>();

// The measurement the next load reserves from. Taken from the first real row
// once one exists, which is the only place the answer is: the tallest cell of a
// row wins, and which cell that is - a wrapped name, a thumbnail, a cell of
// buttons - is a question about this table's data at this width.
useReportListGeometry("row", inner, {
  ready: () => !!props.records.length,
  // The head is skipped rather than the body selected: the header is a row of
  // this same class - shorter than a record, and no indication of how tall one
  // is - and the body is a transition group, which a test env stubs away.
  pick: (host) =>
    Array.from(
      host.querySelectorAll<HTMLElement>(
        ".base-table-row:not([data-test='base-table-skeleton-row'])",
      ),
    ).find((candidate) => !candidate.closest(".base-table-header")),
});

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

const emit = defineEmits(["selected-change", "row-click"]);

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
  loader?: (props: { loading: boolean }) => void;
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
  <Panel
    :id="props.id"
    class="base-table w-full"
    :fill-height="props.fillHeight"
  >
    <PanelHeading v-if="props.title || slots.title" :level="props.titleLevel">
      <slot name="title">{{ props.title }}</slot>
    </PanelHeading>
    <BulkActions :selected="internalSelected" @reset="resetSelected">
      <slot name="selected-actions" :selected="internalSelected" />
    </BulkActions>
    <div class="base-table__outer-wrapper">
      <div class="base-table__wrapper w-full">
        <div class="base-table__loader" v-if="ownLoaderVisible">
          <slot name="loader" :loading="isLoading">
            <Loader :loading="isLoading" :admin="props.admin" />
          </slot>
        </div>
        <table ref="inner" class="base-table__inner">
          <TableHeader
            :id="props.id"
            :col-key="colKey"
            :selected="internalSelected"
            :selectable="props.selectable"
            :loading="isLoading"
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
              'base-table__loading': isLoading,
            }"
            tag="tbody"
            :appear="true"
          >
            <TableRow v-if="props.emptyVisible && !isLoading" key="empty-row">
              <TableCol :colspan="columnCount" variant="empty">
                <slot name="empty">
                  <Empty />
                </slot>
              </TableCol>
            </TableRow>
            <!-- The cells carry the columns' own widths, so the placeholders
                 line up under the header they are waiting beneath rather than
                 laying out a second, narrower table. -->
            <template v-else-if="skeletonVisible">
              <TableRow
                v-for="row in skeletonRowCount"
                :key="`base-table__skeleton-${row}`"
                class="base-table__skeleton-row"
                :class="{
                  'base-table__skeleton-row--with-controls': !!slots.actions,
                }"
                :style="{ height: skeletonRowHeight }"
                aria-hidden="true"
                data-test="base-table-skeleton-row"
              >
                <TableCol v-if="props.selectable" variant="selection" />
                <TableCol
                  v-for="column in filteredColumns"
                  :key="`base-table__skeleton-${colKey}-${column.name}`"
                  :alignment="column.alignment"
                  :style="{
                    'flex-grow': column.flexGrow,
                    width: column.width,
                    'min-width': column.minWidth,
                  }"
                >
                  <span
                    v-if="column.skeletonMedia"
                    class="skeleton-well"
                    :style="{ height: column.skeletonMedia }"
                  />
                  <span v-else class="skeleton-bar" />
                </TableCol>
                <TableCol v-if="slots.actions" variant="actions" />
              </TableRow>
            </template>
            <TableRow
              v-for="record in props.records"
              v-else
              :id="String(primaryValue(record))"
              :key="primaryValue(record)"
              :clickable="props.rowClickable"
              :disabled="props.rowDisabled?.(record)"
              @click="props.rowClickable && emit('row-click', record)"
            >
              <TableCol v-if="props.selectable" variant="selection" @click.stop>
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
              <TableCol v-if="slots.actions" variant="actions" @click.stop>
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
