<script lang="ts">
export default {
  name: "BaseTable",
};
</script>

<script lang="ts" setup generic="T">
import { uniq as uniqArray } from "@/shared/utils/Array";
import Checkbox from "@/shared/components/base/Checkbox/index.vue";
import { v4 as uuidv4 } from "uuid";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import { PanelHeadingLevelEnum } from "@/shared/components/Panel/Heading/types";
import Loader from "@/shared/components/Loader/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import { RouteLocationRaw } from "vue-router";
import {
  BtnVariantsEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";

const { t } = useI18n();

type Props = {
  records: T[];
  columns: BaseTableColumn[];
  primaryKey: keyof T;
  defaultSort?: string;
  title?: string;
  titleLevel?: PanelHeadingLevelEnum;
  loading?: boolean;
  inlineLoader?: boolean;
  emptyBoxVisible?: boolean;
  selectable?: boolean;
  selected?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  title: undefined,
  defaultSort: undefined,
  titleLevel: PanelHeadingLevelEnum.H2,
  loading: false,
  inlineLoader: false,
  emptyBoxVisible: false,
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

const onAllSelectedChange = (value?: string[]) => {
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

const fieldByColumn = (column: BaseTableColumn) => {
  return (column.field || column.name) as keyof T;
};

const primaryValue = (record: T) => {
  return record[props.primaryKey] as string | number;
};

const route = useRoute();

const sortableDirection = (column: BaseTableColumn) => {
  if (!column.sortable && !route.query.s) {
    return undefined;
  }

  if (route.query.s && route.query.s.includes(sortableField(column))) {
    return (route.query.s as string).split(" ")[1];
  } else if (
    props.defaultSort &&
    props.defaultSort.includes(sortableField(column))
  ) {
    return props.defaultSort.split(" ")[1];
  }
};

const sortableField = (column: BaseTableColumn) => {
  return (column.field || column.name) as string;
};

const sortableLink = (column: BaseTableColumn) => {
  const direction = sortableDirection(column) === "asc" ? "desc" : "asc";

  return {
    query: {
      s: `${sortableField(column)} ${direction}`,
    },
  } as RouteLocationRaw;
};

const columnCssClasses = (column: BaseTableColumn) => {
  return {
    [`${column.class}`]: column.class,
    [`base-table__column--sorted-${sortableDirection(column) || "asc"}`]:
      column.sortable,
  };
};

const slots = useSlots();

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
  <Panel class="base-table w-full" :slim="true">
    <PanelHeading v-if="title || slots.title" :level="titleLevel">
      <slot name="title">{{ title }}</slot>
    </PanelHeading>
    <div class="base-table__outer-wrapper">
      <div class="base-table__wrapper w-full">
        <Loader
          v-if="loading && !records.length"
          :loading="loading"
          class="base-table__loader"
        />
        <table class="base-table__inner">
          <transition-group
            name="list"
            :class="{
              'base-table__loading': loading,
            }"
            tag="thead"
            :appear="true"
          >
            <tr v-if="internalSelected.length > 0" key="selected-header">
              <th :colspan="columnCount">
                <div class="base-table__selected">
                  <div class="base-table__selected--count">
                    <span>
                      {{
                        t("filteredTable.labels.selected", {
                          count: internalSelected.length,
                        })
                      }}
                    </span>
                    <Btn
                      v-tooltip="t('filteredTable.actions.unselect')"
                      :size="BtnSizesEnum.SMALL"
                      :variant="BtnVariantsEnum.LINK"
                      inline
                      @click="resetSelected"
                    >
                      <i class="fa fa-times" />
                    </Btn>
                  </div>
                  <div class="base-table__selected--actions">
                    <slot
                      name="selected-actions"
                      :selected="internalSelected"
                    />
                  </div>
                </div>
              </th>
            </tr>
            <tr key="header" class="base-table__header">
              <th v-if="selectable" class="base-table__column">
                <Checkbox
                  v-if="!loading && !emptyBoxVisible"
                  name="all"
                  :model-value="allSelected"
                  inline
                  :partial="internalSelected.length > 0 && !allSelected"
                  @update:model-value="onAllSelectedChange"
                />
              </th>
              <th
                v-for="(column, index) in filteredColumns"
                :key="`base-table__header-${uuid}-${index}-${column.name}`"
                class="base-table__column"
                :class="columnCssClasses(column)"
                :style="{
                  'flex-grow': column.flexGrow,
                  width: column.width,
                  'min-width': column.minWidth,
                }"
              >
                <router-link v-if="column.sortable" :to="sortableLink(column)">
                  {{ column.label }}
                  <i
                    v-if="sortableDirection(column) === 'desc'"
                    class="fad fa-sort-up"
                  />
                  <i v-else class="fad fa-sort-down" />
                </router-link>
                <span v-else>
                  {{ column.label }}
                </span>
              </th>
              <th
                v-if="slots.actions"
                class="base-table__column base-table__column-actions"
              >
                {{ t("labels.actions") }}
              </th>
            </tr>
          </transition-group>
          <transition-group
            name="list"
            :class="{
              'base-table__loading': loading,
            }"
            tag="tbody"
            :appear="true"
          >
            <tr
              v-if="emptyBoxVisible"
              key="empty-row"
              class="base-table__empty"
            >
              <td class="base-table__column" :colspan="columnCount">
                <div class="base-table__empty-inner">
                  <slot name="empty">
                    {{ t("filteredTable.empty.info") }}
                  </slot>
                </div>
              </td>
            </tr>
            <tr
              v-for="record in records"
              v-else
              :id="String(primaryValue(record))"
              :key="primaryValue(record)"
              class="base-table__row"
            >
              <td v-if="selectable" class="base-table__column">
                <Checkbox
                  v-model="internalSelected"
                  name="item"
                  inline
                  :checkbox-value="primaryValue(record)"
                />
              </td>
              <td
                v-for="column in filteredColumns"
                :key="`base-table__item-${uuid}-${column.name}`"
                class="base-table__column"
                :class="{
                  [`${column.class}`]: !!column.class,
                  'base-table__column--centered': column.centered,
                }"
                :style="{
                  'flex-grow': column.flexGrow,
                  width: column.width,
                  'min-width': column.minWidth,
                }"
              >
                <div class="base-table__column-inner">
                  <slot :record="record" :name="`col-${column.name}`">
                    {{ record[fieldByColumn(column)] }}
                  </slot>
                </div>
              </td>
              <td class="base-table__column base-table__column-actions">
                <div class="base-table__column-inner">
                  <slot :record="record" name="actions" />
                </div>
              </td>
            </tr>
          </transition-group>
        </table>
      </div>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
