<script lang="ts">
export default {
  name: "AdminBlueprintsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/Blueprints/FilterForm/index.vue";
import {
  useBlueprints,
  getBlueprintsQueryKey,
  type Blueprint,
  type BlueprintSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useBlueprintFilters } from "@/admin/composables/useBlueprintFilters";

const route = useRoute();

const sorts = computed((): BlueprintSortEnum[] => {
  return route.query.s ? [route.query.s as BlueprintSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const blueprintsQueryKey = computed(() => {
  return getBlueprintsQueryKey(blueprintsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(blueprintsQueryKey);

const { filters, isFilterSelected } = useBlueprintFilters(async () => {
  await refetch();
});

const blueprintsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const {
  data: blueprints,
  refetch,
  ...asyncStatus
} = useBlueprints(blueprintsQueryParams);

const { t, l } = useI18n();

const columns: BaseTableCol<Blueprint>[] = [
  {
    name: "name",
    label: t("labels.blueprint.name"),
    sortable: true,
  },
  {
    name: "makes",
    label: t("labels.admin.blueprints.makes"),
    mobile: false,
  },
  {
    name: "materials",
    label: t("labels.blueprint.materials"),
    mobile: false,
  },
  {
    name: "craftTime",
    label: t("labels.blueprint.craftTime"),
    alignment: "right",
    mobile: false,
    sortable: true,
  },
  {
    name: "slotCount",
    label: t("labels.blueprint.slots"),
    alignment: "right",
    mobile: false,
  },
  {
    name: "source",
    label: t("labels.admin.blueprints.columns.source"),
    alignment: "center",
    mobile: false,
  },
  {
    name: "output",
    label: t("labels.admin.blueprints.columns.output"),
    alignment: "center",
    mobile: false,
  },
  {
    name: "build",
    label: t("labels.admin.blueprints.columns.build"),
    mobile: false,
  },
  {
    name: "createdAt",
    label: t("labels.admin.blueprints.columns.created"),
    mobile: false,
    sortable: true,
  },
];

const materialNames = (record: Blueprint) =>
  (record.materials || []).map((material) => material.name).join(", ");

// A tick and a cross carry the whole answer in these two columns, and an icon
// has no accessible name -- so each one is read out rather than only drawn.
const sourceStatus = (record: Blueprint) =>
  record.sourceUnknown
    ? t("labels.blueprint.noKnownSource")
    : t("labels.admin.blueprints.status.sourceKnown");

const outputStatus = (record: Blueprint) =>
  record.craftableMissing
    ? t("labels.admin.blueprints.noOutput")
    : t("labels.admin.blueprints.status.outputResolved");
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.blueprints.index") }}
    <HeadingSmall v-if="blueprints">
      {{
        t("headlines.pagination.count", {
          current: blueprints?.items.length,
          total: blueprints?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-blueprints"
    :records="blueprints?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="blueprints?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
      >
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-blueprint',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.name || record.scKey }}
          </router-link>
        </template>
        <template #col-makes="{ record }">
          <span v-if="record.craftable">
            {{ record.craftable.name || record.craftable.slug }}
            <span class="blueprint-quiet">{{ record.craftable.type }}</span>
          </span>
          <span v-else class="blueprint-quiet">
            {{ t("labels.admin.blueprints.noOutput") }}
          </span>
        </template>
        <template #col-materials="{ record }">
          {{ materialNames(record) }}
        </template>
        <template #col-craftTime="{ record }">
          {{ record.craftTime }}
        </template>
        <template #col-slotCount="{ record }">
          {{ record.slotCount }}
        </template>
        <template #col-source="{ record }">
          <i
            :class="
              record.sourceUnknown
                ? 'fa-duotone fa-times'
                : 'fa-duotone fa-check'
            "
            aria-hidden="true"
          />
          <span class="sr-only">{{ sourceStatus(record) }}</span>
        </template>
        <template #col-output="{ record }">
          <i
            :class="
              record.craftableMissing
                ? 'fa-duotone fa-times'
                : 'fa-duotone fa-check'
            "
            aria-hidden="true"
          />
          <span class="sr-only">{{ outputStatus(record) }}</span>
        </template>
        <template #col-build="{ record }">
          <span :class="{ 'blueprint-quiet': record.retired }">
            {{ record.build?.version }}
          </span>
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.blueprint-quiet {
  color: var(--color-text-dim);
}
</style>
