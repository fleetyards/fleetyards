<script lang="ts">
export default {
  name: "FleetLogisticsInventoriesPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import InventoryPanel from "@/frontend/components/Logistics/InventoryPanel/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetInventory,
  useFleetInventories,
} from "@/services/fyApi";
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

const {
  data: inventories,
  isLoading,
  refetch,
} = useFleetInventories(fleetSlug, {});

const inventoryList = computed<FleetInventory[]>(
  () => inventories.value?.items ?? [],
);

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:inventories:manage",
    "fleet:inventories:create",
  ]),
);

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

onMounted(() => {
  comlink.on("fleet-inventory-created", () => void refetch());
  comlink.on("fleet-inventory-updated", () => void refetch());
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
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading size="hero" hero>
    {{ t("headlines.logistics.inventories") }}
  </Heading>

  <Teleport v-if="canCreate" to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.logistics.createInventory')"
      mobile-icon-only
      @click="openInventoryModal()"
    >
      <i class="fa-light fa-plus" />
      {{ t("actions.logistics.createInventory") }}
    </Btn>
  </Teleport>

  <Loader :loading="isLoading" />

  <Grid v-if="inventoryList.length" :records="inventoryList" primary-key="id">
    <template #default="{ record }">
      <InventoryPanel
        :inventory="record"
        :to="{
          name: 'fleet-logistics-inventory',
          params: { slug: fleet.slug, inventory: record.slug },
        }"
        :managed-by="record.manager?.username"
        :editable="canCreate"
        @edit="openInventoryModal(record)"
      />
    </template>
  </Grid>

  <Empty
    v-if="!isLoading && !inventoryList.length"
    variant="box"
    hide-actions
    name="inventories"
  />
</template>
