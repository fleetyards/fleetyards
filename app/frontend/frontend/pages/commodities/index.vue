<script lang="ts">
export default {
  name: "CommoditiesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/frontend/components/Commodities/FilterForm/index.vue";
import CommoditiesList from "@/frontend/components/Commodities/List/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useCommoditySortFields } from "@/frontend/composables/useCommoditySortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useCommodityFilters } from "@/frontend/composables/useCommodityFilters";
import {
  useCommodities as useCommoditiesQuery,
  getCommoditiesQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const commoditiesQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const commoditiesQueryKey = computed(() =>
  getCommoditiesQueryKey(commoditiesQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(commoditiesQueryKey);

const { isFilterSelected, getQuery } = useCommodityFilters(async () => {
  await refetch();
});

const {
  data: commodities,
  refetch,
  ...asyncStatus
} = useCommoditiesQuery(commoditiesQueryParams);

// Beside the list rather than inside it: `FilteredList` renders its results
// slot only once the first page has arrived, so a sort line in there is hidden
// exactly while a reader is waiting and most likely to reach for it.
const sortFields = useCommoditySortFields();
</script>

<template>
  <Heading hidden>{{ t("headlines.commodities.index") }}</Heading>

  <FilteredList
    name="commodities"
    :records="commodities?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="commodities"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <!-- Rows rather than cards. Only 63 of the 232 carry a store image, and
         they are SVG inventory glyphs rather than artwork — a leading mark at
         row scale, with nothing to show at card-hero size. The gaps are not
         scattered either: nothing `manmade` has one, nor anything
         `nonmetals`, so a card grid narrowed to a type would be a grid of
         placeholders. -->
    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" icon meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <CommoditiesList :commodities="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="commodities"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
