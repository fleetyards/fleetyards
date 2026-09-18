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
import ComponentRow from "@/frontend/components/Components/Row/index.vue";
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

    <!-- Rows, not cards. Nothing in the catalogue has a picture: the 887
         components that carry an icon are all paints, which the list leaves
         out, so a grid of tiles would be a grid of placeholders. -->
    <template #default="{ records }">
      <div class="components-list">
        <ComponentRow
          v-for="record in records"
          :key="record.id"
          :component="record"
        />
      </div>
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

<style lang="scss" scoped>
.components-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  // The rows carry no margin of their own -- the list spaces them with `gap`
  // instead -- so nothing separated the last one from the paginator under it
  // and the two sat flush. Matches the 20px `filtered-list__actions` puts
  // between the toolbar and the top of the list, so the list is inset the same
  // on both ends.
  margin-bottom: 20px;
}
</style>
