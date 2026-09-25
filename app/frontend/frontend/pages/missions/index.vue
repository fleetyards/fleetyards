<script lang="ts">
export default {
  name: "MissionsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import MissionsList from "@/frontend/components/Missions/List/index.vue";
import FilterForm from "@/frontend/components/Missions/FilterForm/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useMissionSortFields } from "@/frontend/composables/useMissionSortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useMissionFilters } from "@/frontend/composables/useMissionFilters";
import {
  useGameMissions as useMissionsQuery,
  getGameMissionsQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const missionsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const missionsQueryKey = computed(() =>
  getGameMissionsQueryKey(missionsQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(missionsQueryKey);

const { isFilterSelected, getQuery } = useMissionFilters(async () => {
  await refetch();
});

const {
  data: missions,
  refetch,
  ...asyncStatus
} = useMissionsQuery(missionsQueryParams);

// Beside the list rather than inside it, the way the other two tenants put it:
// `FilteredList` renders its results slot only once the first page has
// arrived, so a sort line inside is hidden exactly while a reader is waiting
// and most likely to reach for it.
const sortFields = useMissionSortFields();
</script>

<template>
  <Heading hidden>{{ t("headlines.missions.index") }}</Heading>

  <FilteredList
    name="missions"
    :records="missions?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="missions"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <!-- Rows, like its two neighbours: the export ships no artwork for a
         contract at all, so a grid of tiles would be a grid of placeholders. -->
    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <MissionsList :missions="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="missions"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
