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

const columns: BaseTableCol<Blueprint>[] = [
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "makes",
    label: "Makes",
    mobile: false,
  },
  {
    name: "materials",
    label: "Materials",
    mobile: false,
  },
  {
    name: "craftTime",
    label: "Craft Time",
    alignment: "right",
    mobile: false,
    sortable: true,
  },
  {
    name: "slotCount",
    label: "Slots",
    alignment: "right",
    mobile: false,
  },
  {
    name: "source",
    label: "Source",
    alignment: "center",
    mobile: false,
  },
  {
    name: "output",
    label: "Output",
    alignment: "center",
    mobile: false,
  },
  {
    name: "build",
    label: "Build",
    mobile: false,
  },
  {
    name: "createdAt",
    label: "Created At",
    mobile: false,
    sortable: true,
  },
];

const { t, l } = useI18n();

const materialNames = (record: Blueprint) =>
  (record.materials || []).map((material) => material.name).join(", ");
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
          <i v-if="record.sourceUnknown" class="fa-duotone fa-times" />
          <i v-else class="fa-duotone fa-check" />
        </template>
        <template #col-output="{ record }">
          <i v-if="record.craftableMissing" class="fa-duotone fa-times" />
          <i v-else class="fa-duotone fa-check" />
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
