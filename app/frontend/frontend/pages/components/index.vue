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
import ComponentsTable from "@/frontend/components/Components/Table/index.vue";
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
    placeholders
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

    <!-- A table, not cards: not one component carries a picture -- `store_image`
         is curated and nothing has ever been uploaded against one -- so a grid
         of tiles would be a grid of placeholders. A table also gives the
         columns somewhere to be sorted from, which is what a catalogue of
         3,000 parts is for.
         `placeholders` lets the table draw its own header and a page of
         placeholder rows out of an empty record set, rather than a spinner
         beside a column layout that has not appeared yet. -->
    <template
      #default="{ records, loading: listLoading, emptyVisible: listEmpty }"
    >
      <ComponentsTable
        :components="records"
        :loading="listLoading"
        :empty-visible="listEmpty"
      />
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
