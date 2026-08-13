<script lang="ts">
export default {
  name: "HangarInventoryStockItemPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import StockItemPanel from "@/frontend/components/Logistics/StockItemPanel/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import {
  type HangarInventoryItem,
  type InventoryStockPositionInput,
  useHangarInventory,
  useHangarInventoryStockItem,
  useHangarInventoryItems,
  useDestroyHangarInventoryItem,
  useUpdateHangarInventoryStockItem,
  useDestroyHangarInventoryStockItem,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const comlink = useComlink();
const mobile = useMobile();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const inventorySlug = computed(() => route.params.inventory as string);
const itemSlug = computed(() => route.params.item as string);

const { data: inventory } = useHangarInventory(inventorySlug);

const {
  data: stockItem,
  refetch: refetchStockItem,
  ...asyncStatus
} = useHangarInventoryStockItem(inventorySlug, itemSlug);

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
} = useHangarInventoryItems(inventorySlug, historyQuery, {
  query: { enabled: computed(() => !!stockItem.value) },
});

const historyRecords = computed<HangarInventoryItem[]>(
  () => history.value?.items ?? [],
);

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

        await Promise.all([refetchStockItem(), refetchHistory()]);
      } catch {
        displayAlert({
          text: t("messages.logistics.inventoryItem.destroy.failure"),
        });
      }
    },
  });
};

const inventoryRoute = computed(() => ({
  name: "hangar-inventory",
  params: { inventory: inventorySlug.value },
}));

const updateMutation = useUpdateHangarInventoryStockItem();
const destroyStockItemMutation = useDestroyHangarInventoryStockItem();

const openEditModal = () => {
  if (!stockItem.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/StockItemModal/index.vue"),
    props: {
      stockItem: stockItem.value,
      onSave: async (payload: InventoryStockPositionInput) => {
        const updated = await updateMutation.mutateAsync({
          hangarInventorySlug: inventorySlug.value,
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
            name: "hangar-inventory-item",
            params: { inventory: inventorySlug.value, item: updated.slug },
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
          hangarInventorySlug: inventorySlug.value,
          slug: itemSlug.value,
        });

        displaySuccess({
          text: t("messages.logistics.stockItem.destroy.success"),
        });

        await router.push(inventoryRoute.value);
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
    to: { name: "hangar-inventories" },
    label: t("nav.hangar.inventories"),
  },
  {
    to: {
      name: "hangar-inventory",
      params: { inventory: inventorySlug.value },
    },
    label: inventory.value?.name ?? inventorySlug.value,
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
          <template v-if="stockItem.inventory" #subHeading>
            {{ stockItem.inventory.name }}
          </template>
        </Heading>

        <Teleport v-if="!mobile" to="#header-right">
          <Btn :inline="true" @click="openEditModal">
            <i class="fa-duotone fa-pen" />
            {{ t("actions.logistics.editStockItem") }}
          </Btn>
          <Btn :inline="true" variant="danger" @click="destroyStockItem">
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
    </template>
  </AsyncData>
</template>
