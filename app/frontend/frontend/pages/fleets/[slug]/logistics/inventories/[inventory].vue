<script lang="ts">
export default {
  name: "FleetLogisticsInventoryDetailPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable, {
  type BaseTableCol,
} from "@/shared/components/base/Table/index.vue";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import {
  type Fleet,
  type FleetMember,
  type FleetInventoryItem,
  type FleetInventoryStockItem,
  useFleetInventory,
  useFleetInventoryItems,
  useFleetInventoryStock,
} from "@/services/fyApi";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import InventoryItemFilterForm from "@/frontend/components/Fleets/Logistics/InventoryItemFilterForm/index.vue";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useMobile } from "@/shared/composables/useMobile";

type StockItemWithId = FleetInventoryStockItem & { id: string };

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

const allStockItems = computed<StockItemWithId[]>(() => {
  if (!stockData.value) return [];
  return stockData.value.map((item, index) => ({
    ...item,
    id: `${item.name}-${item.category}-${item.unit}-${index}`,
  }));
});

const stockList = computed(() => {
  const nameFilter = (route.query.nameCont as string)?.toLowerCase();
  const categoryFilter = route.query.categoryEq as string;
  const qualityMin = route.query.qualityGteq
    ? Number(route.query.qualityGteq)
    : undefined;
  const qualityMax = route.query.qualityLteq
    ? Number(route.query.qualityLteq)
    : undefined;

  return allStockItems.value.filter((item) => {
    if (nameFilter && !item.name.toLowerCase().includes(nameFilter)) {
      return false;
    }
    if (categoryFilter && item.category !== categoryFilter) {
      return false;
    }
    if (qualityMin !== undefined && (item.quality ?? 0) < qualityMin) {
      return false;
    }
    if (qualityMax !== undefined && (item.quality ?? 0) > qualityMax) {
      return false;
    }
    return true;
  });
});

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

const activeRecords = computed(() =>
  activeTab.value === "stock" ? stockList.value : itemsList.value,
);

const stockColumns = computed<BaseTableCol<StockItemWithId>[]>(() => [
  {
    name: "name",
    label: t("labels.fleets.logistics.itemName"),
    sortable: true,
    attributeKey: "name",
  },
  {
    name: "category",
    label: t("labels.fleets.logistics.category"),
    sortable: true,
    attributeKey: "category",
    width: "140px",
  },
  {
    name: "quality",
    label: t("labels.fleets.logistics.quality"),
    sortable: true,
    attributeKey: "quality",
    width: "100px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    mobile: false,
  },
  {
    name: "netQuantity",
    label: t("labels.fleets.logistics.quantity"),
    sortable: true,
    attributeKey: "netQuantity",
    width: "140px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
]);

const logColumns = computed<BaseTableCol<FleetInventoryItem>[]>(() => [
  {
    name: "entryType",
    label: t("labels.fleets.logistics.entryType"),
    sortable: true,
    attributeKey: "entryType",
    width: "100px",
  },
  {
    name: "name",
    label: t("labels.fleets.logistics.itemName"),
    sortable: true,
    attributeKey: "name",
  },
  {
    name: "category",
    label: t("labels.fleets.logistics.category"),
    sortable: true,
    attributeKey: "category",
    width: "120px",
    mobile: false,
  },
  {
    name: "quality",
    label: t("labels.fleets.logistics.quality"),
    sortable: true,
    attributeKey: "quality",
    width: "100px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    mobile: false,
  },
  {
    name: "quantity",
    label: t("labels.fleets.logistics.quantity"),
    sortable: true,
    attributeKey: "quantity",
    width: "120px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
  {
    name: "member",
    label: t("labels.fleets.logistics.member"),
    sortable: false,
    width: "120px",
    mobile: false,
  },
  {
    name: "addedBy",
    label: t("labels.fleets.logistics.addedBy"),
    sortable: false,
    width: "120px",
    mobile: false,
  },
  {
    name: "notes",
    label: t("labels.fleets.logistics.notes"),
    sortable: false,
    mobile: false,
  },
]);

const canAddItems = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:inventories:manage",
    "fleet:inventories:update",
  ]),
);

const mobile = useMobile();

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
    label: t("headlines.fleets.logistics.inventories"),
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
          {{ t("labels.fleets.logistics.managedBy") }}
          <MemberName :member="inventory.manager as unknown as FleetMember" />
        </p>
        <p v-if="inventory.description" class="text-muted">
          {{ inventory.description }}
        </p>
        <Teleport v-if="!mobile && canAddItems" to="#header-right">
          <Btn :inline="true" @click="openDepositModal">
            {{ t("actions.fleets.logistics.deposit") }}
          </Btn>
          <Btn :inline="true" @click="openWithdrawModal">
            {{ t("actions.fleets.logistics.withdraw") }}
          </Btn>
          <Btn :inline="true" @click="openCsvImportModal">
            <i class="fa-duotone fa-file-csv" />
            {{ t("actions.fleets.logistics.importCsv") }}
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

          <template #actions-left>
            <BtnGroup inline>
              <Btn
                :active="activeTab === 'stock'"
                inline
                size="small"
                @click="activeTab = 'stock'"
              >
                {{ t("labels.fleets.logistics.stockView") }}
              </Btn>
              <Btn
                :active="activeTab === 'log'"
                inline
                size="small"
                @click="activeTab = 'log'"
              >
                {{ t("labels.fleets.logistics.logView") }}
              </Btn>
            </BtnGroup>
          </template>

          <template #default>
            <!-- Stock View (aggregated) -->
            <BaseTable
              v-if="activeTab === 'stock'"
              :records="stockList"
              :columns="stockColumns"
              primary-key="id"
              :loading="stockLoading"
              :empty-visible="!stockLoading && !stockList.length"
            >
              <template #col-category="{ record }">
                {{ t(`labels.fleets.logistics.categories.${record.category}`) }}
              </template>
              <template #col-netQuantity="{ record }">
                {{ record.netQuantity }}
                {{ t(`labels.fleets.logistics.units.${record.unit}`) }}
              </template>
            </BaseTable>

            <!-- Log View (all entries) -->
            <BaseTable
              v-if="activeTab === 'log'"
              :records="itemsList"
              :columns="logColumns"
              primary-key="id"
              :loading="logLoading"
              :empty-visible="!logLoading && !itemsList.length"
            >
              <template #col-entryType="{ record }">
                <span
                  :class="
                    record.entryType === 'deposit'
                      ? 'text-success'
                      : 'text-danger'
                  "
                >
                  {{
                    t(`labels.fleets.logistics.entryTypes.${record.entryType}`)
                  }}
                </span>
              </template>
              <template #col-category="{ record }">
                {{ t(`labels.fleets.logistics.categories.${record.category}`) }}
              </template>
              <template #col-quantity="{ record }">
                {{ record.quantity }}
                {{ t(`labels.fleets.logistics.units.${record.unit}`) }}
              </template>
              <template #col-member="{ record }">
                <MemberName
                  v-if="record.member"
                  :member="record.member as unknown as FleetMember"
                />
              </template>
              <template #col-addedBy="{ record }">
                <MemberName
                  v-if="record.addedBy"
                  :member="record.addedBy as unknown as FleetMember"
                />
              </template>
              <template #col-notes="{ record }">
                <span class="text-muted">{{ record.notes }}</span>
              </template>
            </BaseTable>
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
