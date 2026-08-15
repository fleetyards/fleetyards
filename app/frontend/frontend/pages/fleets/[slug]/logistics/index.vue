<script lang="ts">
export default {
  name: "FleetLogisticsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetInventoryItem,
  useFleetAllInventoryStock,
  useFleetAllInventoryItems,
} from "@/services/fyApi";
import InventoryItemFilterForm from "@/frontend/components/Logistics/InventoryItemFilterForm/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryStockList } from "@/frontend/composables/useInventoryStockList";
import type { InventoryStockRecord } from "@/frontend/types/logistics";
import { useI18n } from "@/shared/composables/useI18n";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const fleetSlug = computed(() => props.fleet.slug);

const canManageInventories = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:inventories:manage",
    "fleet:inventories:create",
  ]),
);

const activeTab = ref<"stock" | "log">("stock");

const refetchAll = async () => {
  await refetchItems();
};

const { getQuery, isFilterSelected } = useInventoryItemFilters(refetchAll);

const queryParams = computed(() => ({
  q: getQuery(),
}));

// Stock view
const { data: stockData, isLoading: stockLoading } =
  useFleetAllInventoryStock(fleetSlug);

const { stockRecords } = useInventoryStockList(stockData);

// Log view
const {
  data: allItems,
  refetch: refetchItems,
  ...logAsyncStatus
} = useFleetAllInventoryItems(fleetSlug, queryParams);

const logLoading = logAsyncStatus.isLoading;

const itemsList = computed<FleetInventoryItem[]>(
  () => allItems.value?.items ?? [],
);

const activeRecords = computed<(FleetInventoryItem | InventoryStockRecord)[]>(
  () => (activeTab.value === "stock" ? stockRecords.value : itemsList.value),
);

// Every row of the merged stock and log views is grouped per inventory, so it
// carries the inventory it came from and can point at that inventory's item.
const stockItemRoute = (inventorySlug?: string, itemSlug?: string) => ({
  name: "fleet-logistics-inventory-item",
  params: {
    slug: props.fleet.slug,
    inventory: inventorySlug,
    item: itemSlug,
  },
});

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <div class="row">
    <div class="col-12 col-lg-8">
      <Heading size="hero" hero>{{ t("headlines.logistics.index") }}</Heading>
    </div>
    <div class="col-12 col-lg-4 flex justify-end items-center">
      <div v-if="canManageInventories" class="page-actions page-actions-right">
        <Btn
          :to="{
            name: 'fleet-logistics-inventories',
            params: { slug: fleet.slug },
          }"
        >
          {{ t("actions.logistics.viewInventories") }}
        </Btn>
      </div>
    </div>
  </div>

  <FilteredList
    name="all-inventory-items"
    :records="activeRecords"
    :async-status="logAsyncStatus"
    :hide-loading="activeTab === 'stock'"
    :hide-empty="true"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <InventoryItemFilterForm :update-callback="refetchAll" />
    </template>

    <template #actions-left>
      <BtnGroup segmented>
        <Btn :active="activeTab === 'stock'" @click="activeTab = 'stock'">
          {{ t("labels.logistics.stockView") }}
        </Btn>
        <Btn :active="activeTab === 'log'" @click="activeTab = 'log'">
          {{ t("labels.logistics.logView") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #default>
      <InventoryLedgerTables
        :active-tab="activeTab"
        :stock-records="stockRecords"
        :log-records="itemsList"
        :stock-loading="stockLoading"
        :log-loading="logLoading"
        show-inventory
        show-member
      >
        <template #stock-name="{ record }">
          <router-link
            v-if="record.inventory?.slug && record.slug"
            :to="stockItemRoute(record.inventory.slug, record.slug)"
          >
            {{ record.name }}
          </router-link>
          <template v-else>{{ record.name }}</template>
        </template>
        <template #log-name="{ record }">
          <router-link
            v-if="record.inventory?.slug && record.stockSlug"
            :to="stockItemRoute(record.inventory.slug, record.stockSlug)"
          >
            {{ record.name }}
          </router-link>
          <template v-else>{{ record.name }}</template>
        </template>
        <template #member="{ record }">
          <MemberName
            v-if="(record as FleetInventoryItem).member"
            :member="
              (record as FleetInventoryItem).member as unknown as FleetMember
            "
          />
        </template>
      </InventoryLedgerTables>
    </template>
  </FilteredList>
</template>
