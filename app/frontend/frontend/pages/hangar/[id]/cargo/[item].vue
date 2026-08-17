<script lang="ts">
export default {
  name: "HangarVehicleCargoStockItemPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import StockItemPanel from "@/frontend/components/Logistics/StockItemPanel/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import {
  type InventoryItem,
  type InventoryStockPositionInput,
  useShowVehicle,
  useVehicleInventoryStockItem,
  useVehicleInventoryItems,
  useDestroyVehicleInventoryItem,
  useUpdateVehicleInventoryStockItem,
  useDestroyVehicleInventoryStockItem,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const vehicleId = computed(() => route.params.id as string);
const itemSlug = computed(() => route.params.item as string);

const { data: vehicle } = useShowVehicle(vehicleId);

const {
  data: stockItem,
  refetch: refetchStockItem,
  ...asyncStatus
} = useVehicleInventoryStockItem(vehicleId, itemSlug);

const historyQuery = computed(() => ({
  q: {
    nameEq: stockItem.value?.name,
    categoryEq: stockItem.value?.category,
    unitEq: stockItem.value?.unit,
    sorts: "createdAt desc",
  },
}));

const {
  data: history,
  refetch: refetchHistory,
  isLoading: historyLoading,
} = useVehicleInventoryItems(vehicleId, historyQuery, {
  query: { enabled: computed(() => !!stockItem.value) },
});

const historyRecords = computed<InventoryItem[]>(
  () => history.value?.items ?? [],
);

const cargoRoute = computed(() => ({
  name: "hangar-vehicle-cargo",
  params: { id: vehicleId.value },
}));

const vehicleName = computed(() => {
  if (!vehicle.value) return vehicleId.value;

  return vehicle.value.name || vehicle.value.model?.name || vehicleId.value;
});

const destroyMutation = useDestroyVehicleInventoryItem();

const destroyEntry = (entry: InventoryItem) => {
  displayConfirm({
    text: t("messages.logistics.inventoryItem.destroy.confirm"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          vehicleId: vehicleId.value,
          id: entry.id,
        });

        displaySuccess({
          text: t("messages.logistics.inventoryItem.destroy.success"),
        });

        await Promise.all([refetchStockItem(), refetchHistory()]);
      } catch {
        displayAlert({
          text: t("messages.logistics.inventoryItem.destroy.failure"),
        });
      }
    },
  });
};

const updateMutation = useUpdateVehicleInventoryStockItem();
const destroyStockItemMutation = useDestroyVehicleInventoryStockItem();

const openEditModal = () => {
  if (!stockItem.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/StockItemModal/index.vue"),
    props: {
      stockItem: stockItem.value,
      onSave: async (payload: InventoryStockPositionInput) => {
        const updated = await updateMutation.mutateAsync({
          vehicleId: vehicleId.value,
          slug: itemSlug.value,
          data: payload,
        });

        displaySuccess({
          text: t("messages.logistics.stockItem.update.success"),
        });

        // Name, category and unit make up the slug, so an edit moves the item
        // to a new address — follow it instead of leaving a dead page behind.
        if (updated.slug !== itemSlug.value) {
          await router.replace({
            name: "hangar-vehicle-cargo-item",
            params: { id: vehicleId.value, item: updated.slug },
          });
        } else {
          await Promise.all([refetchStockItem(), refetchHistory()]);
        }
      },
    },
  });
};

const destroyStockItem = () => {
  if (!stockItem.value) return;

  displayConfirm({
    text: t("messages.logistics.stockItem.destroy.confirm", {
      count: stockItem.value.entriesCount,
    }),
    onConfirm: async () => {
      try {
        await destroyStockItemMutation.mutateAsync({
          vehicleId: vehicleId.value,
          slug: itemSlug.value,
        });

        displaySuccess({
          text: t("messages.logistics.stockItem.destroy.success"),
        });

        await router.push(cargoRoute.value);
      } catch {
        displayAlert({
          text: t("messages.logistics.stockItem.destroy.failure"),
        });
      }
    },
  });
};

const crumbs = computed(() => [
  {
    to: { name: "hangar" },
    label: t("nav.hangar.index"),
  },
  {
    to: cargoRoute.value,
    label: vehicleName.value,
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <template v-if="stockItem">
        <Heading size="hero" hero inline-sub-heading>
          <template #default>
            {{ stockItem.name }}
          </template>
          <template #subHeading>
            {{ t("nav.hangar.vehicleCargo") }}
          </template>
        </Heading>

        <Teleport to="#header-right">
          <Btn :size="BtnSizesEnum.MD" mobile-icon-only @click="openEditModal">
            <i class="fa-duotone fa-pen" />
            {{ t("actions.logistics.editStockItem") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.MD"
            mobile-icon-only
            :tone="BtnTonesEnum.DANGER"
            @click="destroyStockItem"
          >
            <i class="fa-duotone fa-trash" />
            {{ t("actions.logistics.destroyStockItem") }}
          </Btn>
        </Teleport>

        <StockItemPanel :stock-item="stockItem" />

        <Heading size="lg">
          {{ t("labels.logistics.history") }}
        </Heading>

        <InventoryLedgerTables
          active-tab="log"
          :stock-records="[]"
          :log-records="historyRecords"
          :log-loading="historyLoading"
          show-notes
        >
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
    </template>
  </AsyncData>
</template>
