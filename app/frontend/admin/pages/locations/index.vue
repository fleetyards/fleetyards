<script lang="ts">
export default {
  name: "AdminLocationsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/Locations/FilterForm/index.vue";
import {
  useLocations,
  getLocationsQueryKey,
  type Location,
  type LocationSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useLocationFilters } from "@/admin/composables/useLocationFilters";

const route = useRoute();

const sorts = computed((): LocationSortEnum[] => {
  return route.query.s ? [route.query.s as LocationSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const locationsQueryKey = computed(() => {
  return getLocationsQueryKey(locationsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(locationsQueryKey);

const { filters, isFilterSelected } = useLocationFilters(async () => {
  await refetch();
});

const locationsQueryParams = computed(() => {
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
  data: locations,
  refetch,
  ...asyncStatus
} = useLocations(locationsQueryParams);

const { t } = useI18n();

const columns: BaseTableCol<Location>[] = [
  { name: "name", label: t("labels.location.name"), sortable: true },
  {
    name: "kind",
    label: t("labels.location.kind"),
    mobile: false,
    sortable: true,
  },
  { name: "parent", label: t("labels.admin.locations.parent"), mobile: false },
  {
    name: "starmap",
    label: t("labels.location.starmapVisibility"),
    mobile: false,
  },
  { name: "scKey", label: t("labels.admin.locations.scKey"), mobile: false },
  { name: "version", label: t("labels.admin.locations.build"), mobile: false },
];

const starmap = (record: Location) => {
  if (!record.shownOnStarmap) return t("labels.location.starmapHidden");
  if (record.alwaysShown) return t("labels.location.starmapAlways");

  return t("labels.location.starmapShown");
};
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.locations.index") }}
    <HeadingSmall v-if="locations">
      {{
        t("headlines.pagination.count", {
          current: locations?.items.length,
          total: locations?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-locations"
    :records="locations?.items || []"
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
        :records="locations?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
      >
        <template #col-name="{ record }">
          <router-link
            :to="{ name: 'admin-location', params: { id: record.id } }"
          >
            {{ record.name || record.scKey }}
          </router-link>
        </template>
        <template #col-kind="{ record }">
          {{ t(`labels.location.kinds.${record.kind}`) }}
        </template>
        <template #col-parent="{ record }">
          <span v-if="record.parent">{{ record.parent.name }}</span>
        </template>
        <template #col-starmap="{ record }">
          {{ starmap(record) }}
        </template>
        <template #col-scKey="{ record }">
          <span class="location-quiet">{{ record.scKey }}</span>
        </template>
        <template #col-version="{ record }">
          <span :class="{ 'location-quiet': record.retired }">
            {{ record.version }}
          </span>
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="locations"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="locations"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.location-quiet {
  color: var(--color-text-dim);
}
</style>
