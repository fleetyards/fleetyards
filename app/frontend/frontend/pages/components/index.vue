<script lang="ts">
export default {
  name: "ComponentsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/frontend/components/Components/FilterForm/index.vue";
import ComponentsList from "@/frontend/components/Components/List/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useComponentFilters } from "@/frontend/composables/useComponentFilters";
import {
  useComponents as useComponentsQuery,
  getComponentsQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const componentsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const componentsQueryKey = computed(() =>
  getComponentsQueryKey(componentsQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(componentsQueryKey);

const { isFilterSelected, getQuery } = useComponentFilters(async () => {
  await refetch();
});

const {
  data: components,
  refetch,
  ...asyncStatus
} = useComponentsQuery(componentsQueryParams);
</script>

<template>
  <Heading hidden>{{ t("headlines.components.index") }}</Heading>

  <FilteredList
    name="components"
    :records="components?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="components"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <!-- Rows rather than a table. Not one component carries a picture, so a
         grid of tiles would be a grid of placeholders -- and a row can carry
         the figure that means something for its own kind, where a fixed column
         cannot: a gun leads with sustained DPS and a cooler with cooling rate,
         in the same list. The sort line above the rows is what a row list
         otherwise lacks. -->
    <template #default="{ records, emptyVisible: listEmpty }">
      <ComponentsList :components="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="components"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
