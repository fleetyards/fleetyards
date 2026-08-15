<script lang="ts">
export default {
  name: "FleetLogisticsInventoryStockItemPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import StockItemPanel from "@/frontend/components/Logistics/StockItemPanel/index.vue";
import InventoryLedgerTables from "@/frontend/components/Logistics/InventoryLedgerTables/index.vue";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetInventoryItem,
  type InventoryStockPositionInput,
  useFleetInventory,
  useFleetInventoryStockItem,
  useFleetInventoryItems,
  useDestroyFleetInventoryItem,
  useUpdateFleetInventoryStockItem,
  useDestroyFleetInventoryStockItem,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const comlink = useComlink();
const mobile = useMobile();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);
const inventorySlug = computed(() => route.params.inventory as string);
const itemSlug = computed(() => route.params.item as string);

const { data: inventory } = useFleetInventory(fleetSlug, inventorySlug);

const {
  data: stockItem,
  refetch: refetchStockItem,
  ...asyncStatus
} = useFleetInventoryStockItem(fleetSlug, inventorySlug, itemSlug);

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
} = useFleetInventoryItems(fleetSlug, inventorySlug, historyQuery, {
  query: { enabled: computed(() => !!stockItem.value) },
});

const historyRecords = computed<FleetInventoryItem[]>(
  () => history.value?.items ?? [],
);

const canManageItems = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:inventories:manage",
    "fleet:inventories:update",
  ]),
);

const destroyMutation = useDestroyFleetInventoryItem();

const destroyEntry = (entry: FleetInventoryItem) => {
  displayConfirm({
    text: t("messages.logistics.inventoryItem.destroy.confirm"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          fleetSlug: fleetSlug.value,
          fleetInventorySlug: inventorySlug.value,
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

const updateMutation = useUpdateFleetInventoryStockItem();
const destroyStockItemMutation = useDestroyFleetInventoryStockItem();

const openEditModal = () => {
  if (!stockItem.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/StockItemModal/index.vue"),
    props: {
      stockItem: stockItem.value,
      onSave: async (payload: InventoryStockPositionInput) => {
        const updated = await updateMutation.mutateAsync({
          fleetSlug: fleetSlug.value,
          fleetInventorySlug: inventorySlug.value,
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
            name: "fleet-logistics-inventory-item",
            params: {
              slug: props.fleet.slug,
              inventory: inventorySlug.value,
              item: updated.slug,
            },
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
          fleetSlug: fleetSlug.value,
          fleetInventorySlug: inventorySlug.value,
          slug: itemSlug.value,
        });

        displaySuccess({
          text: t("messages.logistics.stockItem.destroy.success"),
        });

        await router.push({
          name: "fleet-logistics-inventory",
          params: { slug: props.fleet.slug, inventory: inventorySlug.value },
        });
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
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-logistics", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.logistics.index"),
  },
  {
    to: {
      name: "fleet-logistics-inventory",
      params: { slug: props.fleet.slug, inventory: inventorySlug.value },
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

        <Teleport v-if="!mobile && canManageItems" to="#header-right">
          <Btn :size="BtnSizesEnum.MD" @click="openEditModal">
            <i class="fa-duotone fa-pen" />
            {{ t("actions.logistics.editStockItem") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.MD"
            :tone="BtnTonesEnum.DANGER"
            @click="destroyStockItem"
          >
            <i class="fa-duotone fa-trash" />
            {{ t("actions.logistics.destroyStockItem") }}
          </Btn>
        </Teleport>

        <div v-if="mobile && canManageItems" class="stock-item-actions">
          <Btn :size="BtnSizesEnum.SM" @click="openEditModal">
            <i class="fa-duotone fa-pen" />
            {{ t("actions.logistics.editStockItem") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.SM"
            :tone="BtnTonesEnum.DANGER"
            @click="destroyStockItem"
          >
            <i class="fa-duotone fa-trash" />
            {{ t("actions.logistics.destroyStockItem") }}
          </Btn>
        </div>

        <StockItemPanel :stock-item="stockItem" />

        <Heading size="lg">
          {{ t("labels.logistics.history") }}
        </Heading>

        <InventoryLedgerTables
          active-tab="log"
          :stock-records="[]"
          :log-records="historyRecords"
          :log-loading="historyLoading"
          show-member
          show-added-by
          show-notes
        >
          <template #member="{ record }">
            <MemberName
              v-if="(record as FleetInventoryItem).member"
              :member="
                (record as FleetInventoryItem).member as unknown as FleetMember
              "
            />
          </template>
          <template #addedBy="{ record }">
            <MemberName
              v-if="(record as FleetInventoryItem).addedBy"
              :member="
                (record as FleetInventoryItem).addedBy as unknown as FleetMember
              "
            />
          </template>
          <template v-if="canManageItems" #log-actions="{ record }">
            <Btn
              :size="BtnSizesEnum.SM"
              :tone="BtnTonesEnum.DANGER"
              :aria-label="t('actions.logistics.destroyEntry')"
              :title="t('actions.logistics.destroyEntry')"
              @click="destroyEntry(record as FleetInventoryItem)"
            >
              <i class="fa-duotone fa-trash" />
            </Btn>
          </template>
        </InventoryLedgerTables>
      </template>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.stock-item-actions {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}
</style>
