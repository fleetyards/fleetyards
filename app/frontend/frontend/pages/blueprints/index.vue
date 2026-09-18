<script lang="ts">
export default {
  name: "BlueprintsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import BlueprintsList from "@/frontend/components/Blueprints/List/index.vue";
import FilterForm from "@/frontend/components/Blueprints/FilterForm/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useBlueprintSortFields } from "@/frontend/composables/useBlueprintSortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useBlueprintFilters } from "@/frontend/composables/useBlueprintFilters";
import {
  useBlueprints as useBlueprintsQuery,
  getBlueprintsQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const blueprintsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const blueprintsQueryKey = computed(() =>
  getBlueprintsQueryKey(blueprintsQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(blueprintsQueryKey);

const { isFilterSelected, getQuery } = useBlueprintFilters(async () => {
  await refetch();
});

const {
  data: blueprints,
  refetch,
  ...asyncStatus
} = useBlueprintsQuery(blueprintsQueryParams);

// Beside the list rather than inside it, for the reason the components
// catalogue puts it there: `FilteredList` renders its results slot only once
// the first page has arrived, so a sort line inside is hidden exactly while a
// reader is waiting and most likely to reach for it.
const sortFields = useBlueprintSortFields();
</script>

<template>
  <Heading hidden>{{ t("headlines.blueprints.index") }}</Heading>

  <FilteredList
    name="blueprints"
    :records="blueprints?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <!-- Rows, like the components catalogue: a blueprint carries no artwork
         of its own -- it has no name of its own either -- so a grid of tiles
         would be a grid of placeholders. -->
    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #sort>
      <SortBar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <BlueprintsList :blueprints="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
