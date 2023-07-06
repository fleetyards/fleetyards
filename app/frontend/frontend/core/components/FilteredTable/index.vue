<template>
  <Panel>
    <transition-group
      name="fade"
      class="filtered-table"
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
              t("labels.table.selected", {
                count: String(internalSelected.length),
              })
            }}
            <Btn
              v-tooltip="t('actions.unselect')"
              size="small"
              variant="link"
              :inline="true"
              @click.native="resetSelected"
            >
              <i class="fal fa-times" />
            </Btn>
          </div>
          <slot
            :selectedCount="internalSelected.length"
            name="selected-actions"
          />
        </div>
      </div>
      <div key="heading" class="fade-list-item col-12 filtered-table-heading">
        <div class="filtered-table-row">
          <div v-if="selectable && !mobile">
            <Checkbox :value="allSelected" @input="onAllSelectedChange" />
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
              <div v-if="selectable && !mobile">
                <Checkbox
                  v-model="internalSelected"
                  :checkbox-value="record.id"
                />
              </div>
              <template v-for="(column, colIndex) in columns">
                <div
                  :key="`filtered-table-item-${uuid}-${colIndex}-${column.name}`"
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
        v-if="loading"
        key="loading-row"
        class="fade-list-item col-12 filtered-table-loader"
      >
        <div class="filtered-table-row">
          <slot name="loader" :loading="loading">
            <Loader :loading="loading" :inline="true" />
          </slot>
        </div>
      </div>
      <div
        v-else-if="emptyBoxVisible"
        key="empty-row"
        class="fade-list-item col-12 filtered-table-empty"
      >
        <div class="filtered-table-row">
          <slot name="empty">
            {{ t("texts.empty.info") }}
          </slot>
        </div>
      </div>
    </transition-group>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/frontend/core/components/Panel/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { uniq as uniqArray } from "@/frontend/utils/Array";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";
import { v4 as uuidv4 } from "uuid";

export type FilteredTableColumn = {
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
  records: any[];
  columns: FilteredTableColumn[];
  primaryKey: string;
  loading?: boolean;
  emptyBoxVisible?: boolean;
  selectable?: boolean;
  selected?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  emptyBoxVisible: false,
  selectable: false,
  selected: () => [],
});

const internalSelected = ref<string[]>([]);

const mobile = computed(() => Store.getters.mobile);

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
  (value) => {
    internalSelected.value = value;
  }
);

const emit = defineEmits(["selected-change"]);

watch(
  () => internalSelected.value,
  (value) => {
    emit("selected-change", value);
  }
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
      (selected) => !props.records.map((record) => record.id).includes(selected)
    );
  }
};

const resetSelected = () => {
  internalSelected.value = [];
};
</script>

<script lang="ts">
export default {
  name: "FilteredTable",
};
</script>
