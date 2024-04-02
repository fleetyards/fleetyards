<template>
  <Panel class="relative" :slim="true">
    <transition-group
      name="fade"
      class="filtered-table"
      :class="{
        'filtered-table-loading': loading,
      }"
      tag="div"
      :appear="true"
    >
      <div
        v-if="internalSelected.length"
        key="selected-header"
        class="fade-list-item col-12 filtered-table-selected"
      >
        <div class="filtered-table-row">
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
      <div key="heading" class="fade-list-item col-12 filtered-table-heading">
        <div class="filtered-table-row">
          <div v-if="selectable && !mobile" class="col-selectable">
            <Checkbox
              name="all"
              :model-value="allSelected"
              @update:model-value="onAllSelectedChange"
            />
          </div>
          <div
            v-for="(column, index) in columns"
            :key="`filtered-table-heading-${uuid}-${index}-${column.name}`"
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
          v-for="(record, index) in records"
          :key="record[primaryKey]"
          class="fade-list-item col-12 filtered-table-item"
        >
          <slot :record="record" :index="index">
            <div class="filtered-table-row">
              <div v-if="selectable && !mobile" class="col-selectable">
                <Checkbox
                  v-model="internalSelected"
                  name="item"
                  :checkbox-value="record.id"
                />
              </div>
              <template
                v-for="(column, colIndex) in columns"
                :key="`filtered-table-item-${uuid}-${colIndex}-${column.name}`"
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
                    {{ record[column.field || column.name] }}
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
        class="fade-list-item col-12 filtered-table-loader"
      >
        <div class="filtered-table-row">
          <slot name="loader-inline" :loading="loading"></slot>
        </div>
      </div>
      <div
        v-else-if="emptyBoxVisible"
        key="empty-row"
        class="fade-list-item col-12 filtered-table-empty"
      >
        <div class="filtered-table-row">
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

<script lang="ts" setup>
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

export type TableColumn = {
  name: string;
  label: string;
  field?: string;
  class?: string;
  flexGrow?: number;
  width?: string;
  minWidth?: string;
};

const { t } = useI18n();

type Props = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  records: any[];
  columns: TableColumn[];
  primaryKey: string;
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
    .map((record) => record.id)
    .every((recordId) => internalSelected.value.includes(recordId));
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
      ...props.records.map((record) => record.id),
    ].filter(uniqArray);
  } else {
    internalSelected.value = [...internalSelected.value].filter(
      (selected) =>
        !props.records.map((record) => record.id).includes(selected),
    );
  }
};

const resetSelected = () => {
  internalSelected.value = [];
};
</script>

<script lang="ts">
export default {
  name: "BaseTable",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
