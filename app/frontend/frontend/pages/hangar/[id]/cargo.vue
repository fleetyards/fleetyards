<script lang="ts">
export default {
  name: "HangarVehicleCargoPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import InventoryItemFilterForm from "@/frontend/components/Logistics/InventoryItemFilterForm/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import {
  type InventoryItem,
  type Vehicle,
  useVehicleInventory,
  useVehicleInventoryItems,
  useVehicleInventoryStock,
  useDestroyVehicleInventory,
  useDestroyVehicleInventoryItem,
} from "@/services/fyApi";
import { useInventoryItemFilters } from "@/frontend/composables/useInventoryItemFilters";
import { useInventoryStockList } from "@/frontend/composables/useInventoryStockList";
import type {
  InventoryStockRecord,
  InventoryTarget,
} from "@/frontend/types/logistics";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const mobile = useMobile();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const vehicleId = computed(() => props.vehicle.id);

const activeTab = ref<"stock" | "log">("stock");

const target = computed<InventoryTarget>(() => ({
  kind: "vehicle",
  vehicleId: vehicleId.value,
}));

const { data: inventory, refetch: refetchInventory } =
  useVehicleInventory(vehicleId);

const {
  data: stockData,
  isLoading: stockLoading,
  refetch: refetchStock,
} = useVehicleInventoryStock(vehicleId);

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
} = useVehicleInventoryItems(vehicleId, queryParams);

const logLoading = logAsyncStatus.isLoading;

const itemsList = computed<InventoryItem[]>(() => items.value?.items ?? []);

const activeRecords = computed<(InventoryItem | InventoryStockRecord)[]>(() =>
  activeTab.value === "stock" ? stockRecords.value : itemsList.value,
);

const refetch = async () => {
  await refetchInventory();
  await refetchLogItems();
  await refetchStock();
};

const hasCargo = computed(() => (inventory.value?.itemCount ?? 0) > 0);

const stockItemRoute = (slug?: string) => ({
  name: "hangar-vehicle-cargo-item",
  params: { id: vehicleId.value, item: slug },
});

// Players stash cargo outside the grid and personal inventory is not cargo, so
// the capacity is reported rather than enforced.
const cargoCapacity = computed(() => props.vehicle.model?.metrics?.cargo ?? 0);
const shipInventory = computed(
  () => props.vehicle.model?.metrics?.personalInventory ?? 0,
);
// One bucket holds everything a ship carries, so it is measured against
// everything a ship can hold: the grid plus the storage container.
const totalCapacity = computed(() => cargoCapacity.value + shipInventory.value);
const storedScu = computed(() => inventory.value?.totalScu ?? 0);
const overCapacity = computed(
  () => totalCapacity.value > 0 && storedScu.value > totalCapacity.value,
);

const openItemModal = (initialEntryType: "deposit" | "withdrawal") => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/InventoryItemModal/index.vue"),
    props: {
      target: target.value,
      initialEntryType,
    },
  });
};

const openCsvImportModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/CsvImportModal/index.vue"),
    props: { target: target.value },
  });
};

const destroyItemMutation = useDestroyVehicleInventoryItem();

const destroyEntry = (entry: InventoryItem) => {
  displayConfirm({
    text: t("messages.logistics.inventoryItem.destroy.confirm"),
    onConfirm: async () => {
      try {
        await destroyItemMutation.mutateAsync({
          vehicleId: vehicleId.value,
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

const clearCargoMutation = useDestroyVehicleInventory();

const clearCargo = () => {
  displayConfirm({
    text: t("messages.logistics.vehicleInventory.clear.confirm"),
    onConfirm: async () => {
      try {
        await clearCargoMutation.mutateAsync({ vehicleId: vehicleId.value });

        displaySuccess({
          text: t("messages.logistics.vehicleInventory.clear.success"),
        });

        await refetch();
      } catch {
        displayAlert({
          text: t("messages.logistics.vehicleInventory.clear.failure"),
        });
      }
    },
  });
};

onMounted(() => {
  comlink.on("inventory-item-created", () => void refetch());
});
</script>

<template>
  <div class="vehicle-cargo">
    <div class="vehicle-cargo-capacity">
      <span
        class="vehicle-cargo-capacity-value"
        :class="{ over: overCapacity }"
      >
        {{ storedScu }}
        <template v-if="totalCapacity > 0"> / {{ totalCapacity }} </template>
        SCU
      </span>
      <span v-if="totalCapacity > 0" class="vehicle-cargo-capacity-breakdown">
        <span v-if="cargoCapacity > 0">
          {{ t("labels.logistics.cargoGrid") }}: {{ cargoCapacity }} SCU
        </span>
        <span v-if="shipInventory > 0">
          {{ t("labels.logistics.shipInventory") }}: {{ shipInventory }} SCU
        </span>
      </span>
      <span v-if="overCapacity" class="vehicle-cargo-capacity-hint">
        {{ t("labels.logistics.overCapacity") }}
      </span>
    </div>

    <Teleport v-if="!mobile" to="#header-right">
      <Btn :size="BtnSizesEnum.MD" @click="openItemModal('deposit')">
        {{ t("actions.logistics.deposit") }}
      </Btn>
      <Btn :size="BtnSizesEnum.MD" @click="openItemModal('withdrawal')">
        {{ t("actions.logistics.withdraw") }}
      </Btn>
      <Btn :size="BtnSizesEnum.MD" @click="openCsvImportModal">
        <i class="fa-duotone fa-file-csv" />
        {{ t("actions.logistics.importCsv") }}
      </Btn>
      <Btn
        v-if="hasCargo"
        :size="BtnSizesEnum.MD"
        :tone="BtnTonesEnum.DANGER"
        @click="clearCargo"
      >
        <i class="fa-duotone fa-trash" />
        {{ t("actions.logistics.clearCargo") }}
      </Btn>
    </Teleport>

    <FilteredList
      name="vehicle-inventory-items"
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
        <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SM">
          <Btn :size="BtnSizesEnum.SM" @click="openItemModal('deposit')">
            <i class="fa-duotone fa-arrow-down-to-bracket" />
            <span>{{ t("actions.logistics.deposit") }}</span>
          </Btn>
          <Btn :size="BtnSizesEnum.SM" @click="openItemModal('withdrawal')">
            <i class="fa-duotone fa-arrow-up-from-bracket" />
            <span>{{ t("actions.logistics.withdraw") }}</span>
          </Btn>
          <Btn :size="BtnSizesEnum.SM" @click="openCsvImportModal">
            <i class="fa-duotone fa-file-csv" />
            <span>{{ t("actions.logistics.importCsv") }}</span>
          </Btn>
          <Btn v-if="hasCargo" :size="BtnSizesEnum.SM" @click="clearCargo">
            <i class="fa-duotone fa-trash" />
            <span>{{ t("actions.logistics.clearCargo") }}</span>
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
            <BtnGroup>
              <Btn
                :size="BtnSizesEnum.SM"
                :tone="BtnTonesEnum.DANGER"
                :aria-label="t('actions.logistics.destroyEntry')"
                :title="t('actions.logistics.destroyEntry')"
                @click="destroyEntry(record as InventoryItem)"
              >
                <i class="fa-duotone fa-trash" />
              </Btn>
            </BtnGroup>
          </template>
        </InventoryLedgerTables>
      </template>
    </FilteredList>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-cargo {
  &-capacity {
    display: flex;
    align-items: baseline;
    gap: 10px;
    margin-bottom: 10px;
  }

  &-capacity-value {
    font-size: 1.4em;
    font-weight: 700;

    &.over {
      color: $danger;
    }
  }

  &-capacity-breakdown {
    display: flex;
    gap: 10px;
    font-size: 0.85em;
    opacity: 0.75;
  }

  &-capacity-hint {
    font-size: 0.85em;
    color: $danger;
  }
}
</style>
