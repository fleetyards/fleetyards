<script lang="ts">
export default {
  name: "FleetLogisticsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetInventory,
  type FleetInventoryItem,
  useFleetInventories,
  useFleetAllInventoryStock,
  useFleetAllInventoryItems,
} from "@/services/fyApi";
import InventoryPanel from "@/frontend/components/Logistics/InventoryPanel/index.vue";
import InventoryItemFilterForm from "@/frontend/components/Logistics/InventoryItemFilterForm/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryStockList } from "@/frontend/composables/useInventoryStockList";
import type { InventoryStockRecord } from "@/frontend/types/logistics";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);

const canManageInventories = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:inventories:manage",
    "fleet:inventories:create",
  ]),
);

const activeTab = ref<"stock" | "log">("stock");

const {
  data: inventories,
  isLoading: inventoriesLoading,
  refetch: refetchInventories,
} = useFleetInventories(fleetSlug, {});

const inventoryList = computed<FleetInventory[]>(
  () => inventories.value?.items ?? [],
);

const refetchAll = async () => {
  await refetchItems();
};

const { getQuery, isFilterSelected } = useInventoryItemFilters(refetchAll);

const queryParams = computed(() => ({
  q: getQuery(),
}));

// Stock view
const {
  data: stockData,
  isLoading: stockLoading,
  refetch: refetchStock,
} = useFleetAllInventoryStock(fleetSlug);

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

const openInventoryModal = (inventory?: FleetInventory) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Logistics/InventoryModal/index.vue"),
    props: {
      fleet: props.fleet,
      inventory,
    },
  });
};

const refetchEverything = async () => {
  await refetchInventories();
  await refetchStock();
  await refetchItems();
};

const inventoryCreatedComlink = ref();
const inventoryUpdatedComlink = ref();
const inventoryItemCreatedComlink = ref();

onMounted(() => {
  inventoryCreatedComlink.value = comlink.on(
    "fleet-inventory-created",
    () => void refetchEverything(),
  );
  inventoryUpdatedComlink.value = comlink.on(
    "fleet-inventory-updated",
    () => void refetchEverything(),
  );
  inventoryItemCreatedComlink.value = comlink.on(
    "fleet-inventory-item-created",
    () => void refetchEverything(),
  );
});

onUnmounted(() => {
  inventoryCreatedComlink.value();
  inventoryUpdatedComlink.value();
  inventoryItemCreatedComlink.value();
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
    <div class="col-12">
      <Heading size="hero" hero>{{ t("headlines.logistics.index") }}</Heading>
    </div>
  </div>

  <Teleport v-if="canManageInventories" to="#header-right">
    <Btn :size="BtnSizesEnum.MD" mobile-icon-only @click="openInventoryModal()">
      <i class="fa-light fa-plus" />
      {{ t("actions.logistics.createInventory") }}
    </Btn>
  </Teleport>

  <Loader :loading="inventoriesLoading" />

  <Grid v-if="inventoryList.length" :records="inventoryList" primary-key="id">
    <template #default="{ record }">
      <InventoryPanel
        :inventory="record"
        :to="{
          name: 'fleet-logistics-inventory',
          params: { slug: fleet.slug, inventory: record.slug },
        }"
        :manager="record.manager"
        :editable="canManageInventories"
        @edit="openInventoryModal(record)"
      />
    </template>
  </Grid>

  <Empty
    v-if="!inventoriesLoading && !inventoryList.length"
    variant="box"
    hide-actions
    name="inventories"
  />

  <FilteredList
    v-if="inventoryList.length"
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
