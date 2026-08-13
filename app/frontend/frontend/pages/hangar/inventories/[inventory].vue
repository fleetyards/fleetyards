<script lang="ts">
export default {
  name: "HangarInventoryDetailPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type HangarInventoryItem,
  useHangarInventory,
  useHangarInventoryItems,
  useHangarInventoryStock,
  useDestroyHangarInventoryItem,
} from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import InventoryItemFilterForm from "@/frontend/components/Logistics/InventoryItemFilterForm/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryStockList } from "@/frontend/composables/useInventoryStockList";
import type { InventoryStockRecord } from "@/frontend/types/logistics";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";

const { t } = useI18n();
const route = useRoute();
const comlink = useComlink();
const mobile = useMobile();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const inventorySlug = computed(() => route.params.inventory as string);

const activeTab = ref<"stock" | "log">("stock");

const {
  data: inventory,
  refetch: refetchInventory,
  ...asyncInventoryStatus
} = useHangarInventory(inventorySlug);

const {
  data: stockData,
  isLoading: stockLoading,
  refetch: refetchStock,
} = useHangarInventoryStock(inventorySlug);

const { stockRecords } = useInventoryStockList(stockData);

const refetchAll = async () => {
  await refetchLogItems();
};

const { getQuery, isFilterSelected } = useInventoryItemFilters(refetchAll);

const queryParams = computed(() => ({
  q: getQuery(),
}));

const {
  data: items,
  refetch: refetchLogItems,
  ...logAsyncStatus
} = useHangarInventoryItems(inventorySlug, queryParams);

const logLoading = logAsyncStatus.isLoading;

const itemsList = computed<HangarInventoryItem[]>(
  () => items.value?.items ?? [],
);

const activeRecords = computed<(HangarInventoryItem | InventoryStockRecord)[]>(
  () => (activeTab.value === "stock" ? stockRecords.value : itemsList.value),
);

const refetch = async () => {
  await refetchLogItems();
  await refetchStock();
};

const stockItemRoute = (slug?: string) => ({
  name: "hangar-inventory-item",
  params: { inventory: inventorySlug.value, item: slug },
});

const destroyMutation = useDestroyHangarInventoryItem();

const destroyEntry = (entry: HangarInventoryItem) => {
  displayConfirm({
    text: t("messages.logistics.inventoryItem.destroy.confirm"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          hangarInventorySlug: inventorySlug.value,
          id: entry.id,
        });

        displaySuccess({
          text: t("messages.logistics.inventoryItem.destroy.success"),
        });

        await refetch();
      } catch {
        displayAlert({
          text: t("messages.logistics.inventoryItem.destroy.failure"),
        });
      }
    },
  });
};

const openItemModal = (initialEntryType: "deposit" | "withdrawal") => {
  if (!inventory.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Logistics/InventoryItemModal/index.vue"),
    props: {
      inventory: inventory.value,
      initialEntryType,
    },
  });
};

const openCsvImportModal = () => {
  if (!inventory.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Logistics/CsvImportModal/index.vue"),
    props: { inventory: inventory.value },
  });
};

const openEditModal = () => {
  if (!inventory.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Logistics/InventoryModal/index.vue"),
    props: { inventory: inventory.value },
  });
};

onMounted(() => {
  comlink.on("hangar-inventory-item-created", () => void refetch());
  comlink.on("hangar-inventory-updated", () => void refetchInventory());
});

const crumbs = computed(() => [
  {
    to: { name: "hangar" },
    label: t("nav.hangar.index"),
  },
  {
    to: { name: "hangar-inventories" },
    label: t("nav.hangar.inventories"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <AsyncData :async-status="asyncInventoryStatus">
    <template #resolved>
      <template v-if="inventory">
        <Heading size="hero" hero inline-sub-heading>
          <template #default>
            {{ inventory.name }}
          </template>
          <template v-if="inventory.location" #subHeading>
            {{ inventory.location }}
          </template>
        </Heading>
        <p v-if="inventory.description" class="text-muted">
          {{ inventory.description }}
        </p>

        <Teleport v-if="!mobile" to="#header-right">
          <Btn :inline="true" @click="openItemModal('deposit')">
            {{ t("actions.logistics.deposit") }}
          </Btn>
          <Btn :inline="true" @click="openItemModal('withdrawal')">
            {{ t("actions.logistics.withdraw") }}
          </Btn>
          <Btn :inline="true" @click="openCsvImportModal">
            <i class="fa-duotone fa-file-csv" />
            {{ t("actions.logistics.importCsv") }}
          </Btn>
          <Btn :inline="true" @click="openEditModal">
            <i class="fa-duotone fa-pen" />
          </Btn>
        </Teleport>

        <FilteredList
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
            <BtnGroup inline>
              <Btn
                :active="activeTab === 'stock'"
                inline
                size="small"
                @click="activeTab = 'stock'"
              >
                {{ t("labels.logistics.stockView") }}
              </Btn>
              <Btn
                :active="activeTab === 'log'"
                inline
                size="small"
                @click="activeTab = 'log'"
              >
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
              show-notes
            >
              <template #stock-name="{ record }">
                <router-link :to="stockItemRoute(record.slug)">
                  {{ record.name }}
                </router-link>
              </template>
              <template #log-name="{ record }">
                <router-link :to="stockItemRoute(record.stockSlug)">
                  {{ record.name }}
                </router-link>
              </template>
              <template #log-actions="{ record }">
                <Btn
                  :size="BtnSizesEnum.SMALL"
                  variant="danger"
                  :aria-label="t('actions.logistics.destroyEntry')"
                  :title="t('actions.logistics.destroyEntry')"
                  @click="destroyEntry(record as HangarInventoryItem)"
                >
                  <i class="fa-duotone fa-trash" />
                </Btn>
              </template>
            </InventoryLedgerTables>
          </template>
        </FilteredList>
      </template>
    </template>
  </AsyncData>
</template>
