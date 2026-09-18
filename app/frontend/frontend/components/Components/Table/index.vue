<script lang="ts">
export default {
  name: "ComponentsTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import ComponentLeadMetric from "@/frontend/components/Components/LeadMetric/index.vue";
import ComponentCategoryIcon from "@/frontend/components/Components/CategoryIcon/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type BaseTableCol,
  BaseTableColAlignmentEnum,
} from "@/shared/components/base/Table/types";
import { type Component } from "@/services/fyApi";

type Props = {
  components: Component[];
  loading?: boolean;
  emptyVisible?: boolean;
  skeletonRows?: number;
};

defineProps<Props>();

const { t, tExists } = useI18n();

// Every heading here is a label the site already carries in all seven locales:
// a table of components is the same vocabulary as the hardpoint list and the
// filter form, and a fresh `components.table.columns.*` namespace would ship as
// "translation missing" in six of them.
//
// `size` is deliberately not sortable. The column is a string holding "10" and
// "12" beside "M" and "S", so ordering it puts 10 and 12 ahead of 2 -- see
// `Component::ALLOWED_SORTING_PARAMS`, which leaves it out for the same reason.
// A sort that reads as broken is worse than one not offered.
//
// The sort names are the server's, not the payload's, where the two differ:
// `componentSubType` is what `ALLOWED_SORTING_PARAMS` whitelists while the
// payload calls the field `subType`, so the column carries the sort name and
// renders through a slot.
const columns = computed<BaseTableCol<Component>[]>(() => [
  // Its own fixed column rather than sitting inside the name cell, so the
  // names start on one edge whatever the glyph beside them is -- an svg and a
  // Font Awesome character do not measure the same, and a category with no
  // icon at all measures nothing. No heading: the icon *is* the category, which
  // has a column of its own further along.
  {
    name: "icon",
    label: "",
    width: "40px",
    alignment: BaseTableColAlignmentEnum.CENTER,
  },
  {
    name: "name",
    label: t("labels.hardpoint.name"),
    width: "auto",
    minWidth: "220px",
    sortable: true,
  },
  {
    name: "manufacturerName",
    label: t("labels.filters.manufacturer"),
    minWidth: "150px",
    sortable: true,
  },
  {
    name: "category",
    label: t("labels.component.category"),
    minWidth: "140px",
    sortable: true,
  },
  {
    name: "componentSubType",
    label: t("labels.component.subType"),
    minWidth: "130px",
    sortable: true,
  },
  // No heading: the figure differs per row, so there is nothing true to put at
  // the top of the column. See ComponentLeadMetric.
  {
    name: "metrics",
    label: "",
    minWidth: "200px",
  },
  // Last, and right-aligned: these two are what the eye runs down a column of
  // rows for, so they hold the edge the way they did as badges on a row.
  //
  // `sizeOrder` is the sort rather than `size`, which is a string ransacker --
  // ordering it puts 10 and 12 ahead of 2. The numeric one is a name of its own
  // so `size_eq` keeps matching what it always matched. It renders through a
  // slot because `attributeKey` is the render field as well as the sort field.
  {
    name: "size",
    label: t("labels.hardpoint.size"),
    attributeKey: "sizeOrder",
    width: "90px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    sortable: true,
  },
  {
    name: "grade",
    label: t("labels.component.grade"),
    width: "100px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    sortable: true,
  },
]);

// The payload carries the game's own category string ("quantumdrive"). The
// hardpoint list already names all of them in every locale, so the label comes
// from there rather than a second vocabulary -- falling back to the raw key
// spaced and capitalised for a category a patch introduces before anyone writes
// a label for it.
const categoryLabel = (key?: string | null) => {
  if (!key) return undefined;

  const path = `labels.hardpoint.categories.${key}`;

  return tExists(path) ? t(path) : key;
};
</script>

<template>
  <BaseTable
    :records="components"
    primary-key="slug"
    default-sort="name asc"
    :columns="columns"
    :loading="loading"
    :empty-visible="emptyVisible"
    :skeleton-rows="skeletonRows"
  >
    <template #empty>
      <Empty :name="t('labels.filters.components.name')" />
    </template>

    <template #col-icon="{ record }">
      <ComponentCategoryIcon :category="record.category" />
    </template>

    <!-- A component with no name has no slug either, and `router-link` throws
         on a missing required param rather than rendering nothing. The
         catalogue filters those out, so this is the guard that keeps one
         reaching the page from taking the table down with it. -->
    <template #col-name="{ record }">
      <router-link
        v-if="record.slug"
        :to="{ name: 'component', params: { slug: record.slug } }"
      >
        {{ record.name }}
      </router-link>
      <span v-else>{{ record.name }}</span>
    </template>

    <template #col-manufacturerName="{ record }">
      {{ record.manufacturer?.name }}
    </template>

    <template #col-category="{ record }">
      {{ categoryLabel(record.category) }}
    </template>

    <template #col-componentSubType="{ record }">
      {{ record.subType }}
    </template>

    <template #col-metrics="{ record }">
      <ComponentLeadMetric :component="record" />
    </template>

    <!-- The pill the row carried, minus its own label: the column heading says
         which figure this is, and repeating it inside every cell would say it
         3,000 times. -->
    <template #col-size="{ record }">
      <span v-if="record.size" class="components-table__badge">
        {{ record.size }}
      </span>
    </template>

    <template #col-grade="{ record }">
      <span v-if="record.gradeLabel" class="components-table__badge">
        {{ record.gradeLabel }}
      </span>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
@import "index";
</style>
