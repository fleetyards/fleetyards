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

const props = defineProps<Props>();

const { t, tExists, toNumber } = useI18n();

// The eight figures inside `type_data` the server can sort on, each with the
// label the site already uses for it. Every one belongs to exactly one category
// -- shield HP to shieldgenerator, cooling rate to cooler -- so the label is
// the category's own rather than a new vocabulary, and all eight resolve in all
// seven locales.
//
// `sort` is the name `Component::ALLOWED_SORTING_PARAMS` whitelists; `field` is
// what the payload calls it, camelised from the snake_case key the column
// stores.
const METRIC_COLUMNS = [
  {
    field: "maxHealth",
    sort: "maxHealth",
    labelKey: "labels.hardpoint.shields.hp",
  },
  {
    field: "maxRegen",
    sort: "maxRegen",
    labelKey: "labels.hardpoint.shields.regen",
  },
  { field: "health", sort: "health", labelKey: "labels.hardpoint.armor.hp" },
  {
    field: "powerBase",
    sort: "powerBase",
    labelKey: "labels.hardpoint.powerPlants.output",
  },
  {
    field: "coolingRate",
    sort: "coolingRate",
    labelKey: "labels.hardpoint.coolers.coolingRate",
  },
  {
    field: "driveSpeed",
    sort: "driveSpeed",
    labelKey: "labels.hardpoint.quantumDrives.speed",
  },
  {
    field: "jumpRange",
    sort: "jumpRange",
    labelKey: "labels.hardpoint.quantumDrives.range",
  },
  {
    field: "thrustCapacity",
    sort: "thrustCapacity",
    labelKey: "labels.hardpoint.thrusters.thrust",
  },
] as const;

const route = useRoute();

// Every value in the table that the catalogue can be narrowed by is a link that
// narrows it. The filters live in the route query rather than in a store, so
// this is a plain link: it is shareable, the back button undoes it, and the
// filter form prefills from the same place and shows what was chosen.
//
// `page` is dropped because the row that was clicked is almost never on the
// same page of a different, smaller result set.
//
// Name is left alone on purpose -- it is the link to the component itself, and
// filtering a catalogue down to the one row you are already looking at is not
// a thing anyone wants.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const metricValue = (record: Component, field: string) =>
  (record.typeData as Record<string, unknown> | undefined)?.[field];

// Only the metrics the rows on screen actually carry. Unfiltered, the list is
// mostly paints and none of these appear; narrowed to shield generators, HP and
// Regen show up as columns that sort -- which is the question "shields by HP"
// needed somewhere to be asked from.
//
// Driven by the records rather than by the chosen category so it needs no map
// from one to the other, and so it still works for a search that happens to
// land on one kind of part.
const metricColumns = computed<BaseTableCol<Component>[]>(() =>
  METRIC_COLUMNS.filter((metric) =>
    props.components.some(
      (record) => metricValue(record, metric.field) != null,
    ),
  ).map((metric) => ({
    name: metric.field,
    label: t(metric.labelKey),
    attributeKey: metric.sort,
    minWidth: "110px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    sortable: true,
  })),
);

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
  // The generic column only while no metric has a column of its own: with HP
  // and Regen named at the top of their own, repeating them per row under no
  // heading says the same thing twice.
  //
  // No heading on it, deliberately: the figure it shows differs per row, so
  // there is nothing true to write above it. See ComponentLeadMetric.
  ...(metricColumns.value.length
    ? metricColumns.value
    : [
        {
          name: "metrics",
          label: "",
          minWidth: "200px",
        },
      ]),
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
    width: "116px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    sortable: true,
  },
  {
    name: "grade",
    label: t("labels.component.grade"),
    width: "124px",
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
      <router-link
        v-if="record.manufacturer?.name"
        :to="filterLink('manufacturerNameCont', record.manufacturer.name)"
      >
        {{ record.manufacturer.name }}
      </router-link>
    </template>

    <template #col-category="{ record }">
      <router-link
        v-if="record.category"
        :to="filterLink('categoryIn', record.category)"
      >
        {{ categoryLabel(record.category) }}
      </router-link>
    </template>

    <template #col-componentSubType="{ record }">
      <router-link
        v-if="record.subType"
        :to="filterLink('componentSubTypeIn', record.subType)"
      >
        {{ record.subType }}
      </router-link>
    </template>

    <template #col-metrics="{ record }">
      <ComponentLeadMetric :component="record" />
    </template>

    <template
      v-for="metric in metricColumns"
      #[`col-${metric.name}`]="{ record }"
      :key="metric.name"
    >
      <span class="components-table__metric">
        {{ toNumber(metricValue(record, metric.name) as number) }}
      </span>
    </template>

    <!-- The pill the row carried, label and all. A bare "1" or "A" says nothing
         once it is away from its heading -- on a phone, in a screenshot, or to
         anyone scanning the right-hand edge rather than reading across.
         Built from `hardpoint.size` and `component.grade`, which are translated
         in all seven locales; `component.size` reads "Size: %{size}" and is
         still English in four of them, and nothing uses it. -->
    <template #col-size="{ record }">
      <span v-if="record.size" class="components-table__badge">
        <span class="components-table__badge-label">
          {{ t("labels.hardpoint.size") }}
        </span>
        <span class="components-table__badge-value">{{ record.size }}</span>
      </span>
    </template>

    <template #col-grade="{ record }">
      <span v-if="record.gradeLabel" class="components-table__badge">
        <span class="components-table__badge-label">
          {{ t("labels.component.grade") }}
        </span>
        <span class="components-table__badge-value">
          {{ record.gradeLabel }}
        </span>
      </span>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
@import "index";
</style>
