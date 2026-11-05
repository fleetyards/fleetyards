<script lang="ts">
export default {
  name: "EquipmentPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import PageActions from "@/shared/components/PageActions/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/frontend/components/Equipment/FilterForm/index.vue";
import EquipmentList from "@/frontend/components/Equipment/List/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useCatalogueLayout } from "@/frontend/composables/useCatalogueLayout";
import { useEquipmentSortFields } from "@/frontend/composables/useEquipmentSortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useEquipmentFilters } from "@/frontend/composables/useEquipmentFilters";
import { useEquipment as useEquipmentQuery } from "@/services/fyApi";

const { t } = useI18n();

const { gridView, detailsVisible, openDisplayOptionsModal } =
  useCatalogueLayout("equipment");

const equipmentQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const { perPage, page, updatePerPage } = usePagination();

const { isFilterSelected, getQuery } = useEquipmentFilters(async () => {
  await refetch();
});

const {
  data: equipment,
  refetch,
  ...asyncStatus
} = useEquipmentQuery(equipmentQueryParams);

const sortFields = useEquipmentSortFields(() => equipment.value?.items || []);
</script>

<template>
  <Heading hidden>{{ t("headlines.equipment.index") }}</Heading>

  <PageActions>
    <Btn
      data-test="equipment-compare-link"
      :to="{ name: 'compare-equipment' }"
      :aria-label="t('actions.compare.item')"
    >
      <i class="fa-duotone fa-code-compare" />
      {{ t("actions.compare.item") }}
    </Btn>
  </PageActions>

  <FilteredList
    name="equipment"
    :records="equipment?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #actions-right>
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.models.openTableConfiguration')"
        data-test="equipment-display-options"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>
    </template>

    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="equipment"
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
        variant="summary"
        :filter-visible="filterVisible"
      />
      <RowsSkeleton v-else :count="count" icon meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty, filterVisible }">
      <EquipmentList
        :equipment="records"
        :empty-visible="listEmpty"
        :grid-view="gridView"
        :details-visible="detailsVisible"
        :filter-visible="filterVisible"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="equipment"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
