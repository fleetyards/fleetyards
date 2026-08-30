<script lang="ts">
export default {
  name: "AdminFleetInventoryPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { BaseTableCol } from "@/shared/components/base/Table/types";
import { usePagination } from "@/shared/composables/usePagination";
import DetailList from "@/admin/components/DetailList/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";
import {
  type Fleet,
  type FleetInventoryItem,
  useFleetInventory as useFleetInventoryQuery,
  useFleetInventoryItems as useFleetInventoryItemsQuery,
  getFleetInventoryItemsQueryKey,
} from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, lUtc: l } = useI18n();
const route = useRoute();

const inventoryId = computed(() => route.params.inventoryId as string);

const { data: inventory, ...asyncStatus } = useFleetInventoryQuery(
  props.fleet.id,
  inventoryId,
);

const itemsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const itemsQueryKey = computed(() =>
  getFleetInventoryItemsQueryKey(
    props.fleet.id,
    inventoryId.value,
    itemsQueryParams.value,
  ),
);

const { perPage, page, updatePerPage } = usePagination(itemsQueryKey);

const { data: items } = useFleetInventoryItemsQuery(
  props.fleet.id,
  inventoryId,
  itemsQueryParams,
);

const details = computed<Detail[]>(() =>
  inventory.value
    ? [
        {
          label: t("labels.fleet.inventories.name"),
          value: inventory.value.name,
        },
        { label: t("labels.slug"), value: inventory.value.slug },
        {
          label: t("labels.fleet.inventories.description"),
          value: inventory.value.description,
        },
        {
          label: t("labels.fleet.inventories.location"),
          value: inventory.value.location,
        },
        {
          label: t("labels.fleet.inventories.visibility"),
          value: t(
            `labels.fleet.inventories.visibilities.${inventory.value.visibility}`,
          ),
        },
        {
          label: t("labels.fleet.inventories.manager"),
          value: inventory.value.managerUsername,
        },
        {
          label: t("labels.createdAt"),
          value: l(inventory.value.createdAt, "datetime.formats.short"),
        },
      ]
    : [],
);

const columns: BaseTableCol<FleetInventoryItem>[] = [
  { name: "name", label: t("labels.inventoryItems.name") },
  { name: "category", label: t("labels.inventoryItems.category") },
  { name: "entryType", label: t("labels.inventoryItems.entryType") },
  { name: "quantity", label: t("labels.inventoryItems.quantity") },
  { name: "createdAt", label: t("labels.createdAt") },
];
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <Heading hero class="mb-4">{{ inventory?.name }}</Heading>

      <DetailList :details="details" />

      <Heading class="mt-8 mb-4">
        {{ t("headlines.admin.fleets.inventoryItems") }}
      </Heading>

      <BaseTable
        v-if="items"
        :records="items.items || []"
        primary-key="id"
        :columns="columns"
        :empty-visible="(items.items || []).length === 0"
      >
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-fleet-inventory-item',
              params: {
                id: props.fleet.id,
                inventoryId,
                itemId: record.id,
              },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-category="{ record }">
          {{ t(`labels.inventoryItems.categories.${record.category}`) }}
        </template>
        <template #col-entryType="{ record }">
          {{ t(`labels.inventoryItems.entryTypes.${record.entryType}`) }}
        </template>
        <template #col-quantity="{ record }">
          {{ record.quantity }}
          {{ t(`labels.inventoryItems.units.${record.unit}`) }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
      </BaseTable>

      <Paginator
        v-if="items"
        :query-result-ref="items"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />

      <Heading class="mt-8 mb-4">
        {{ t("headlines.admin.fleets.history") }}
      </Heading>

      <VersionHistory :item-id="inventoryId" item-type="FleetInventory" />
    </template>
  </AsyncData>
</template>
