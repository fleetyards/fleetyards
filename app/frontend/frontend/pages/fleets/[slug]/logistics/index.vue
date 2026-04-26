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
import BaseTable, {
  type BaseTableCol,
} from "@/shared/components/base/Table/index.vue";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetInventoryItem,
  type FleetInventoryStockItem,
  useFleetAllInventoryStock,
  useFleetAllInventoryItems,
} from "@/services/fyApi";
import InventoryItemFilterForm from "@/frontend/components/Fleets/Logistics/InventoryItemFilterForm/index.vue";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { checkAccess } from "@/shared/utils/Access";

type StockItemWithId = FleetInventoryStockItem & { id: string };

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

// Log view
const {
  data: allItems,
  refetch: refetchItems,
  ...logAsyncStatus
} = useFleetAllInventoryItems(fleetSlug, queryParams);

const logLoading = logAsyncStatus.isLoading;

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);

const route = useRoute();

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

const activeRecords = computed<(FleetInventoryItem | StockItemWithId)[]>(() =>
  activeTab.value === "stock" ? stockList.value : itemsList.value,
);

const itemsList = computed<FleetInventoryItem[]>(
  () => allItems.value?.items ?? [],
);

const stockColumns = computed<BaseTableCol<StockItemWithId>[]>(() => [
  {
    name: "name",
    label: t("labels.fleets.logistics.itemName"),
    sortable: true,
    attributeKey: "name",
  },
  {
    name: "inventory",
    label: t("labels.fleets.logistics.inventory"),
    sortable: false,
    width: "180px",
    mobile: false,
  },
  {
    name: "category",
    label: t("labels.fleets.logistics.category"),
    sortable: true,
    attributeKey: "category",
    width: "140px",
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
    name: "inventory",
    label: t("labels.fleets.logistics.inventory"),
    sortable: false,
    width: "160px",
    mobile: false,
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
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <div class="row">
    <div class="col-12 col-lg-8">
      <Heading size="hero" hero>{{
        t("headlines.fleets.logistics.index")
      }}</Heading>
    </div>
    <div class="col-12 col-lg-4 flex justify-end items-center">
      <div v-if="canManageInventories" class="page-actions page-actions-right">
        <Btn
          :to="{
            name: 'fleet-logistics-inventories',
            params: { slug: fleet.slug },
          }"
          :inline="true"
        >
          {{ t("actions.fleets.logistics.viewInventories") }}
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
          size="small"
          inline
          @click="activeTab = 'log'"
        >
          {{ t("labels.fleets.logistics.logView") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #default>
      <!-- Stock View -->
      <BaseTable
        v-if="activeTab === 'stock'"
        :records="stockList"
        :columns="stockColumns"
        primary-key="id"
        :loading="stockLoading"
        :empty-visible="!stockLoading && !stockList.length"
      >
        <template #col-inventory="{ record }">
          <span class="text-muted">{{ record.inventory?.name }}</span>
        </template>
        <template #col-category="{ record }">
          {{ t(`labels.fleets.logistics.categories.${record.category}`) }}
        </template>
        <template #col-quality="{ record }">
          <template v-if="record.qualityMin != null">
            <template v-if="record.qualityMin === record.qualityMax">
              {{ record.qualityMin }}
            </template>
            <template v-else>
              {{ record.qualityMin }} - {{ record.qualityMax }}
            </template>
          </template>
          <template v-else-if="record.quality != null">
            {{ record.quality }}
          </template>
        </template>
        <template #col-netQuantity="{ record }">
          {{ record.netQuantity }}
          {{ t(`labels.fleets.logistics.units.${record.unit}`) }}
        </template>
      </BaseTable>

      <!-- Log View -->
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
              record.entryType === 'deposit' ? 'text-success' : 'text-danger'
            "
          >
            {{ t(`labels.fleets.logistics.entryTypes.${record.entryType}`) }}
          </span>
        </template>
        <template #col-inventory="{ record }">
          <span class="text-muted">{{ record.inventory?.name }}</span>
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
      </BaseTable>
    </template>
  </FilteredList>
</template>
