<script lang="ts">
export default {
  name: "FleetLogisticsInventoriesPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import InventoryPanel from "@/frontend/components/Fleets/Logistics/InventoryPanel/index.vue";
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

const openCreateModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Logistics/InventoryModal/index.vue"),
    props: {
      fleet: props.fleet,
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
  <div class="row">
    <div class="col-12 col-lg-8">
      <Heading size="hero" hero>{{
        t("headlines.fleets.logistics.inventories")
      }}</Heading>
    </div>
    <div class="col-12 col-lg-4 flex justify-end items-center">
      <div v-if="canCreate" class="page-actions page-actions-right">
        <Btn :inline="true" @click="openCreateModal">
          {{ t("actions.fleets.logistics.createInventory") }}
        </Btn>
      </div>
    </div>
  </div>

  <Loader :loading="isLoading" />

  <Grid v-if="inventoryList.length" :records="inventoryList" primary-key="id">
    <template #default="{ record }">
      <InventoryPanel
        :inventory="record"
        :fleet="fleet"
        :fleet-slug="fleet.slug"
        :editable="canCreate"
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
