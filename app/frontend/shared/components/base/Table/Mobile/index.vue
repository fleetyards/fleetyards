<script lang="ts">
export default {
  name: "BaseTableMobile",
};
</script>

<script lang="ts" setup generic="T">
import Btn from "@/shared/components/base/Btn/index.vue";
import { uniq as uniqArray } from "@/shared/utils/Array";
import Checkbox from "@/shared/components/base/Checkbox/index.vue";
import { v4 as uuidv4 } from "uuid";
import Panel from "@/shared/components/Panel/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

export type TableColumn<Record> = {
  name: string;
  label: string;
  field?: keyof Record;
  class?: string;
  flexGrow?: number;
  width?: string;
  minWidth?: string;
};

const { t } = useI18n();

type Props = {
  records: T[];
  columns: TableColumn<T>[];
  primaryKey: keyof T;
  loading?: boolean;
  inlineLoader?: boolean;
  emptyBoxVisible?: boolean;
  selectable?: boolean;
  selected?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  inlineLoader: false,
  emptyBoxVisible: false,
  selectable: false,
  selected: () => [],
});

const internalSelected = ref<string[]>([]);

const mobile = useMobile();

const uuid = ref<string>(uuidv4());

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
  uuid.value = uuidv4();
});

const onAllSelectedChange = (value: string[]) => {
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

const fieldByColumn = (column: TableColumn<T>) => {
  return column.field || (column.name as keyof T);
};

const primaryValue = (record: T) => {
  return record[props.primaryKey] as string | number;
};
</script>

<template>
  <Panel class="base-table__wrapper" :slim="true">
    <transition-group
      name="fade"
      class="base-table"
      :class="{
        'base-table__loading': loading,
      }"
      tag="div"
      :appear="true"
    >
      <div
        v-if="internalSelected.length"
        key="selected-header"
        class="fade-list-item col-12 base-table__selected"
      >
        <div class="base-table__row">
          <div class="selected-count">
            {{
              t("filteredTable.labels.selected", {
                count: internalSelected.length,
              })
            }}
            <Btn
              v-tooltip="t('filteredTable.actions.unselect')"
              :size="BtnSizesEnum.SMALL"
              :variant="BtnVariantsEnum.LINK"
              :inline="true"
              @click="resetSelected"
            >
              <i class="fal fa-times" />
            </Btn>
          </div>
          <slot
            :selected-count="internalSelected.length"
            name="selected-actions"
          />
        </div>
      </div>
      <div key="heading" class="fade-list-item col-12 base-table__heading">
        <div class="base-table__row">
          <div v-if="selectable && !mobile" class="col-selectable">
            <Checkbox
              name="all"
              :model-value="allSelected"
              @update:model-value="onAllSelectedChange"
            />
          </div>
          <div
            v-for="(column, index) in columns"
            :key="`base-table__heading-${uuid}-${index}-${column.name}`"
            :class="column.class"
            :style="{
              'flex-grow': column.flexGrow,
              width: column.width,
              'min-width': column.minWidth,
            }"
          >
            {{ column.label }}
          </div>
        </div>
      </div>
      <template v-if="records.length">
        <div
          v-for="(record, rowIndex) in records"
          :key="primaryValue(record)"
          class="fade-list-item col-12 base-table__item"
        >
          <slot :record="record" :index="rowIndex">
            <div class="base-table__row">
              <div v-if="selectable && !mobile" class="col-selectable">
                <Checkbox
                  v-model="internalSelected"
                  name="item"
                  :checkbox-value="primaryValue(record)"
                />
              </div>
              <template
                v-for="column in columns"
                :key="`base-table__item-${uuid}-${column.name}`"
              >
                <div
                  :class="column.class"
                  :style="{
                    'flex-grow': column.flexGrow,
                    width: column.width,
                    'min-width': column.minWidth,
                  }"
                >
                  <slot :record="record" :name="`col-${column.name}`">
                    {{ record[fieldByColumn(column)] }}
                  </slot>
                </div>
              </template>
            </div>
          </slot>
        </div>
      </template>
      <div
        v-if="loading && inlineLoader"
        key="loading-row"
        class="fade-list-item col-12 base-table__loader"
      >
        <div class="base-table__row">
          <slot name="loader-inline" :loading="loading"></slot>
        </div>
      </div>
      <div
        v-else-if="emptyBoxVisible"
        key="empty-row"
        class="fade-list-item col-12 base-table__empty"
      >
        <div class="base-table__row">
          <slot name="empty">
            {{ t("filteredTable.empty.info") }}
          </slot>
        </div>
      </div>
    </transition-group>
    <slot v-if="!inlineLoader" name="loader" :loading="loading">
      <Loader :loading="loading" relative />
    </slot>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
