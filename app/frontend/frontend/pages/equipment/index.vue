<script lang="ts">
export default {
  name: "EquipmentPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/frontend/components/Equipment/FilterForm/index.vue";
import EquipmentList from "@/frontend/components/Equipment/List/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useEquipmentSortFields } from "@/frontend/composables/useEquipmentSortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useEquipmentFilters } from "@/frontend/composables/useEquipmentFilters";
import {
  useEquipment as useEquipmentQuery,
  getEquipmentQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const equipmentQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const equipmentQueryKey = computed(() =>
  getEquipmentQueryKey(equipmentQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(equipmentQueryKey);

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

  <FilteredList
    name="equipment"
    :records="equipment?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="equipment"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <!-- Rows rather than cards: no equipment carries a picture, so a grid would
         be a grid of placeholders. -->
    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" icon meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <EquipmentList :equipment="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="equipment"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
