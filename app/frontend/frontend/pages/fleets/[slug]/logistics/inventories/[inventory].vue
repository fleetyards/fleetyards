<script lang="ts">
export default {
  name: "FleetLogisticsInventoryDetailPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetMember,
  type FleetInventoryItem,
  useFleetInventory,
  useFleetInventoryItems,
  useFleetInventoryStock,
  useDestroyFleetInventoryItem,
} from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import InventoryItemFilterForm from "@/frontend/components/Logistics/InventoryItemFilterForm/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryStockList } from "@/frontend/composables/useInventoryStockList";
import type { InventoryStockRecord } from "@/frontend/types/logistics";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);
const inventorySlug = computed(() => route.params.inventory as string);

const activeTab = ref<"stock" | "log">("stock");

const {
  data: inventory,
  refetch: refetchInventory,
  ...asyncInventoryStatus
} = useFleetInventory(fleetSlug, inventorySlug);

// Stock view (aggregated)
const {
  data: stockData,
  isLoading: stockLoading,
  refetch: refetchStock,
} = useFleetInventoryStock(fleetSlug, inventorySlug);

const { stockRecords } = useInventoryStockList(stockData);

const refetchAll = async () => {
  await refetchLogItems();
};

const { getQuery, isFilterSelected } = useInventoryItemFilters(refetchAll);

const queryParams = computed(() => ({
  q: getQuery(),
}));

// Log view (raw entries)
const {
  data: items,
  refetch: refetchLogItems,
  ...logAsyncStatus
} = useFleetInventoryItems(fleetSlug, inventorySlug, queryParams);

const logLoading = logAsyncStatus.isLoading;

const refetch = async () => {
  await refetchLogItems();
  await refetchStock();
};

const itemsList = computed<FleetInventoryItem[]>(
  () => items.value?.items ?? [],
);

const activeRecords = computed<(FleetInventoryItem | InventoryStockRecord)[]>(
  () => (activeTab.value === "stock" ? stockRecords.value : itemsList.value),
);

const canAddItems = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:inventories:manage",
    "fleet:inventories:update",
  ]),
);

const mobile = useMobile();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const stockItemRoute = (slug?: string) => ({
  name: "fleet-logistics-inventory-item",
  params: {
    slug: props.fleet.slug,
    inventory: inventorySlug.value,
    item: slug,
  },
});

const destroyMutation = useDestroyFleetInventoryItem();

const destroyEntry = (entry: FleetInventoryItem) => {
  displayConfirm({
    text: t("messages.logistics.inventoryItem.destroy.confirm"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          fleetSlug: props.fleet.slug,
          fleetInventorySlug: inventorySlug.value,
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

const openDepositModal = () => {
  if (!inventory.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Logistics/InventoryItemModal/index.vue"),
    props: {
      fleet: props.fleet,
      inventory: inventory.value,
      initialEntryType: "deposit",
    },
  });
};

const openWithdrawModal = () => {
  if (!inventory.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Logistics/InventoryItemModal/index.vue"),
    props: {
      fleet: props.fleet,
      inventory: inventory.value,
      initialEntryType: "withdrawal",
    },
  });
};

const openCsvImportModal = () => {
  if (!inventory.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Logistics/CsvImportModal/index.vue"),
    props: {
      fleet: props.fleet,
      inventory: inventory.value,
    },
  });
};

onMounted(() => {
  comlink.on("fleet-inventory-item-created", () => void refetch());
  comlink.on("fleet-inventory-updated", () => void refetchInventory());
});

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-logistics", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.logistics.index"),
  },
  {
    to: {
      name: "fleet-logistics-inventories",
      params: { slug: props.fleet.slug },
    },
    label: t("headlines.logistics.inventories"),
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
          <template
            v-if="(inventory as unknown as { location?: string }).location"
            #subHeading
          >
            {{ (inventory as unknown as { location: string }).location }}
          </template>
        </Heading>
        <p v-if="inventory.manager" class="inventory-detail-manager">
          {{ t("labels.logistics.managedBy") }}
          <MemberName :member="inventory.manager as unknown as FleetMember" />
        </p>
        <p v-if="inventory.description" class="text-muted">
          {{ inventory.description }}
        </p>
        <Teleport v-if="!mobile && canAddItems" to="#header-right">
          <Btn :size="BtnSizesEnum.MD" @click="openDepositModal">
            {{ t("actions.logistics.deposit") }}
          </Btn>
          <Btn :size="BtnSizesEnum.MD" @click="openWithdrawModal">
            {{ t("actions.logistics.withdraw") }}
          </Btn>
          <Btn :size="BtnSizesEnum.MD" @click="openCsvImportModal">
            <i class="fa-duotone fa-file-csv" />
            {{ t("actions.logistics.importCsv") }}
          </Btn>
        </Teleport>

        <FilteredList
          name="inventory-items"
          :records="activeRecords"
          :async-status="logAsyncStatus"
          :hide-loading="activeTab === 'stock'"
          :hide-empty="true"
          :is-filter-selected="isFilterSelected"
        >
          <template #filter>
            <InventoryItemFilterForm :update-callback="refetchAll" />
          </template>

          <template #actions-right>
            <BtnDropdown
              v-if="mobile && canAddItems"
              :size="BtnSizesEnum.SMALL"
            >
              <Btn :size="BtnSizesEnum.SMALL" @click="openDepositModal">
                <i class="fa-duotone fa-arrow-down-to-bracket" />
                <span>{{ t("actions.logistics.deposit") }}</span>
              </Btn>
              <Btn :size="BtnSizesEnum.SMALL" @click="openWithdrawModal">
                <i class="fa-duotone fa-arrow-up-from-bracket" />
                <span>{{ t("actions.logistics.withdraw") }}</span>
              </Btn>
              <Btn :size="BtnSizesEnum.SMALL" @click="openCsvImportModal">
                <i class="fa-duotone fa-file-csv" />
                <span>{{ t("actions.logistics.importCsv") }}</span>
              </Btn>
            </BtnDropdown>
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
              show-member
              show-added-by
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
              <template v-if="canAddItems" #log-actions="{ record }">
                <Btn
                  :size="BtnSizesEnum.SMALL"
                  variant="danger"
                  :aria-label="t('actions.logistics.destroyEntry')"
                  :title="t('actions.logistics.destroyEntry')"
                  @click="destroyEntry(record as FleetInventoryItem)"
                >
                  <i class="fa-duotone fa-trash" />
                </Btn>
              </template>
              <template #member="{ record }">
                <MemberName
                  v-if="(record as FleetInventoryItem).member"
                  :member="
                    (record as FleetInventoryItem)
                      .member as unknown as FleetMember
                  "
                />
              </template>
              <template #addedBy="{ record }">
                <MemberName
                  v-if="(record as FleetInventoryItem).addedBy"
                  :member="
                    (record as FleetInventoryItem)
                      .addedBy as unknown as FleetMember
                  "
                />
              </template>
            </InventoryLedgerTables>
          </template>
        </FilteredList>
      </template>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.inventory-detail-manager {
  white-space: nowrap;
}
</style>
