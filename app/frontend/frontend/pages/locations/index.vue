<script lang="ts">
export default {
  name: "LocationsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import LocationsList from "@/frontend/components/Locations/List/index.vue";
import FilterForm from "@/frontend/components/Locations/FilterForm/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import SystemCard from "@/frontend/components/Locations/SystemCard/index.vue";
import { useLocationSortFields } from "@/frontend/composables/useLocationSortFields";
import { useLocationFilters } from "@/frontend/composables/useLocationFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import {
  LocationKindEnum,
  useLocations,
  getLocationsQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const locationsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const locationsQueryKey = computed(() =>
  getLocationsQueryKey(locationsQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(locationsQueryKey);

const { isFilterSelected, getQuery } = useLocationFilters(async () => {
  await refetch();
});

const {
  data: locations,
  refetch,
  ...asyncStatus
} = useLocations(locationsQueryParams);

const sortFields = useLocationSortFields();

// Every system, laid out as its bodies, above the list. Hidden while a
// filter narrows the list: the reader is searching then, not browsing.
const { data: systems } = useLocations({
  q: { kindEq: LocationKindEnum.SYSTEM },
});
</script>

<template>
  <Heading hidden>{{ t("headlines.locations.index") }}</Heading>

  <section
    v-if="!isFilterSelected && systems?.items.length"
    class="locations-systems"
    :aria-label="t('labels.location.systems')"
  >
    <SystemCard
      v-for="system in systems.items"
      :key="system.id"
      :system="system"
    />
  </section>

  <FilteredList
    name="locations"
    :records="locations?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="locations"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <LocationsList :locations="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="locations"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.locations-systems {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 24px;
}
</style>
