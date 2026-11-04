<script lang="ts">
export default {
  name: "ComponentsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import PageActions from "@/shared/components/PageActions/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/frontend/components/Components/FilterForm/index.vue";
import ComponentsList from "@/frontend/components/Components/List/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useCatalogueLayoutStore } from "@/frontend/stores/catalogueLayout";
import { useComlink } from "@/shared/composables/useComlink";
import { useComponentSortFields } from "@/frontend/composables/useComponentSortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useComponentFilters } from "@/frontend/composables/useComponentFilters";
import { useComponents as useComponentsQuery } from "@/services/fyApi";

const { t } = useI18n();

const catalogueLayoutStore = useCatalogueLayoutStore();

const gridView = computed(() => catalogueLayoutStore.componentsGridView);

const detailsVisible = computed(
  () => catalogueLayoutStore.componentsDetailsVisible,
);

const comlink = useComlink();

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/shared/components/DisplayOptionsModal/index.vue"),
    props: {
      gridView: gridView.value,
      testPrefix: "components",
      updateCallback: (next: boolean) => {
        catalogueLayoutStore.componentsGridView = next;
      },
      detailsVisible: detailsVisible.value,
      updateDetailsCallback: (next: boolean) => {
        catalogueLayoutStore.componentsDetailsVisible = next;
      },
    },
  });
};

const componentsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const { perPage, page, updatePerPage } = usePagination();

const { isFilterSelected, getQuery } = useComponentFilters(async () => {
  await refetch();
});

const {
  data: components,
  refetch,
  ...asyncStatus
} = useComponentsQuery(componentsQueryParams);

// Beside the list rather than inside it: `FilteredList` renders its results
// slot only once the first page has arrived, so a sort line in there is hidden
// exactly while a reader is waiting and most likely to reach for it.
const sortFields = useComponentSortFields(() => components.value?.items || []);
</script>

<template>
  <Heading hidden>{{ t("headlines.components.index") }}</Heading>

  <PageActions>
    <Btn
      data-test="components-compare-link"
      :to="{ name: 'compare-components' }"
      :aria-label="t('actions.compare.item')"
    >
      <i class="fa-duotone fa-code-compare" />
      {{ t("actions.compare.item") }}
    </Btn>
  </PageActions>

  <FilteredList
    name="components"
    :records="components?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #actions-right>
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.models.openTableConfiguration')"
        data-test="components-display-options"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>
    </template>

    <template #filter>
      <FilterForm hide-quicksearch />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="components"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <!-- Placeholders in the shape of the layout the reader picked, so the
         paginator below does not jump as the records arrive. -->
    <template #skeleton="{ count, filterVisible }">
      <GridSkeleton
        v-if="gridView"
        grid-base="compact"
        :details="detailsVisible"
        :filter-visible="filterVisible"
      />
      <RowsSkeleton v-else :count="count" icon meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty, filterVisible }">
      <ComponentsList
        :components="records"
        :empty-visible="listEmpty"
        :grid-view="gridView"
        :details-visible="detailsVisible"
        :filter-visible="filterVisible"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="components"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
