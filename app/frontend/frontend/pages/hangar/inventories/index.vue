<script lang="ts">
export default {
  name: "HangarInventoriesPage",
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
import InventoryPanel from "@/frontend/components/Logistics/InventoryPanel/index.vue";
import InventoryItemFilterForm from "@/frontend/components/Logistics/InventoryItemFilterForm/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import {
  type HangarInventory,
  type HangarInventoryItem,
  useHangarInventories,
  useHangarAllInventoryStock,
  useHangarAllInventoryItems,
} from "@/services/fyApi";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryStockList } from "@/frontend/composables/useInventoryStockList";
import type { InventoryStockRecord } from "@/frontend/types/logistics";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();
const comlink = useComlink();

const activeTab = ref<"stock" | "log">("stock");

const {
  data: inventories,
  isLoading: inventoriesLoading,
  refetch: refetchInventories,
} = useHangarInventories();

const inventoryList = computed<HangarInventory[]>(
  () => inventories.value?.items ?? [],
);

const refetchAll = async () => {
  await refetchItems();
};

const { getQuery, isFilterSelected } = useInventoryItemFilters(refetchAll);

const queryParams = computed(() => ({
  q: getQuery(),
}));

const {
  data: stockData,
  isLoading: stockLoading,
  refetch: refetchStock,
} = useHangarAllInventoryStock();

const { stockRecords } = useInventoryStockList(stockData);

const {
  data: allItems,
  refetch: refetchItems,
  ...logAsyncStatus
} = useHangarAllInventoryItems(queryParams);

const logLoading = logAsyncStatus.isLoading;

const itemsList = computed<HangarInventoryItem[]>(
  () => allItems.value?.items ?? [],
);

const activeRecords = computed<(HangarInventoryItem | InventoryStockRecord)[]>(
  () => (activeTab.value === "stock" ? stockRecords.value : itemsList.value),
);

// Every row of the merged stock and log views is grouped per inventory, so it
// carries the inventory it came from and can point at that inventory's item.
const stockItemRoute = (inventorySlug?: string, itemSlug?: string) => ({
  name: "hangar-inventory-item",
  params: { inventory: inventorySlug, item: itemSlug },
});

// A ship inventory shares its slug with every other ship of that model, so it is
// reached through the ship rather than through /hangar/inventories/:slug.
const inventoryRoute = (inventory: HangarInventory) =>
  inventory.vehicle
    ? { name: "hangar-vehicle-cargo", params: { id: inventory.vehicle.id } }
    : { name: "hangar-inventory", params: { inventory: inventory.slug } };

const openInventoryModal = (inventory?: HangarInventory) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Logistics/InventoryModal/index.vue"),
    props: { inventory },
  });
};

const refetchEverything = async () => {
  await refetchInventories();
  await refetchStock();
  await refetchItems();
};

onMounted(() => {
  comlink.on("hangar-inventory-created", () => void refetchEverything());
  comlink.on("hangar-inventory-updated", () => void refetchEverything());
  comlink.on("inventory-item-created", () => void refetchEverything());
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />
  <Heading size="hero" hero>
    {{ t("headlines.logistics.hangarInventories") }}
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      data-test="hangar-inventory-create"
      mobile-icon-only
      @click="openInventoryModal()"
    >
      <i class="fa-light fa-plus" />
      {{ t("actions.logistics.createInventory") }}
    </Btn>
  </Teleport>

  <Loader :loading="inventoriesLoading" />

  <Grid v-if="inventoryList.length" :records="inventoryList" primary-key="id">
    <template #default="{ record }">
      <InventoryPanel
        :inventory="record"
        :to="inventoryRoute(record)"
        :editable="!record.vehicle"
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
    name="hangar-inventory-items"
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
      </InventoryLedgerTables>
    </template>
  </FilteredList>
</template>
