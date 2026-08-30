<script lang="ts">
export default {
  name: "AdminFleetInventoriesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { BaseTableCol } from "@/shared/components/base/Table/types";
import { usePagination } from "@/shared/composables/usePagination";
import {
  type Fleet,
  type FleetInventory,
  useFleetInventories as useFleetInventoriesQuery,
  getFleetInventoriesQueryKey,
} from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, lUtc: l } = useI18n();

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const queryKey = computed(() =>
  getFleetInventoriesQueryKey(props.fleet.id, queryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { data: inventories, ...asyncStatus } = useFleetInventoriesQuery(
  props.fleet.id,
  queryParams,
);

const columns: BaseTableCol<FleetInventory>[] = [
  {
    name: "name",
    label: t("labels.fleet.inventories.name"),
  },
  {
    name: "location",
    label: t("labels.fleet.inventories.location"),
  },
  {
    name: "visibility",
    label: t("labels.fleet.inventories.visibility"),
  },
  {
    name: "managerUsername",
    label: t("labels.fleet.inventories.manager"),
  },
  {
    name: "itemsCount",
    label: t("labels.fleet.inventories.itemsCount"),
  },
  {
    name: "createdAt",
    label: t("labels.createdAt"),
  },
];
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.fleets.inventories") }}
    <HeadingSmall v-if="inventories">
      {{
        t("headlines.pagination.count", {
          current: inventories?.items.length,
          total: inventories?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    v-if="inventories"
    name="admin-fleet-inventories"
    :records="inventories.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="inventories.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
      >
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-fleet-inventory',
              params: { id: props.fleet.id, inventoryId: record.id },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-visibility="{ record }">
          {{ t(`labels.fleet.inventories.visibilities.${record.visibility}`) }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="inventories"
        :query-result-ref="inventories"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="inventories"
        :query-result-ref="inventories"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
