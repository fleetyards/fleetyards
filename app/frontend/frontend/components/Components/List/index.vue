<script lang="ts">
export default {
  name: "ComponentsList",
};
</script>

<script lang="ts" setup>
import ComponentRow from "@/frontend/components/Components/Row/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import {
  METRIC_FIELDS,
  metricValue,
} from "@/frontend/components/Components/metricFields";
import { type Component } from "@/services/fyApi";

type Props = {
  components: Component[];
  emptyVisible?: boolean;
};

const props = withDefaults(defineProps<Props>(), { emptyVisible: false });

const { t } = useI18n();

// Rows rather than a table: not one component carries a picture, so a grid of
// tiles would be a grid of placeholders -- and a row can carry the figure that
// means something for its own kind, which a fixed column cannot. A gun leads
// with sustained DPS and a cooler with cooling rate, in the same list.
//
// What a table gives and this does not is a column to read down. The sort line
// covers the ordering half of that; comparing two figures at a glance is the
// half a row list genuinely cannot do.
//
// The sort line is the only reason these are described as columns: `SortBar`
// takes the shape a table is built from, and describing them this way means one
// list of sorts rather than one per control.
const sortFields = computed<BaseTableCol<Component>[]>(() => [
  { name: "name", label: t("labels.hardpoint.name"), sortable: true },
  {
    name: "manufacturerName",
    label: t("labels.filters.manufacturer"),
    sortable: true,
  },
  { name: "category", label: t("labels.component.category"), sortable: true },
  {
    name: "componentSubType",
    label: t("labels.component.subType"),
    sortable: true,
  },
  // `sizeOrder` rather than `size`, which is a string ransacker -- ordering it
  // puts 10 and 12 ahead of 2.
  {
    name: "size",
    label: t("labels.hardpoint.size"),
    attributeKey: "sizeOrder",
    sortable: true,
  },
  { name: "grade", label: t("labels.component.grade"), sortable: true },

  // Only the metrics the rows on screen actually carry. Unfiltered the list is
  // mostly paints and none appear; narrowed to shield generators, HP and Regen
  // join the line. Driven by the records rather than by the chosen category, so
  // it needs no map from one to the other and still works for a search that
  // happens to land on one kind of part.
  ...METRIC_FIELDS.filter((metric) =>
    props.components.some(
      (record) => metricValue(record, metric.field) != null,
    ),
  ).map((metric) => ({
    name: metric.field,
    label: t(metric.labelKey),
    attributeKey: metric.sort,
    sortable: true,
  })),
]);
</script>

<template>
  <div class="components-list">
    <!-- A row list has no column headings, so this is the whole sort control
         rather than a second way to reach one. -->
    <SortBar :columns="sortFields" default-sort="name asc" />

    <Empty v-if="emptyVisible" :name="t('labels.filters.components.name')" />

    <div v-else class="components-list__rows">
      <ComponentRow
        v-for="record in components"
        :key="record.id"
        :component="record"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
