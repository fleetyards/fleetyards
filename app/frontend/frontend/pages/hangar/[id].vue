<script lang="ts">
export default {
  name: "HangarVehicleRouterView",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import VehicleHero from "@/frontend/components/Vehicles/Hero/index.vue";
import { FeatureFlagName, useShowVehicle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { checkFeatures } from "@/shared/utils/Access";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import { routes as vehicleRoutes } from "@/frontend/pages/hangar/[id]/routes";

const { t } = useI18n();
const { isFeatureEnabled } = useFeatures();

// A tab behind a flag stays out of the bar entirely; its endpoints answer 403
// until the flag is on, so showing it would only offer a dead end.
const tabs = computed(() =>
  vehicleRoutes.filter(
    (tab) =>
      // A route reached from a tab rather than being one -- the cargo ledger is
      // the same hold, seen differently.
      tab.meta?.nav !== "hidden" &&
      checkFeatures(tab.meta?.feature, isFeatureEnabled),
  ),
);

const route = useRoute();

// The ship's header: the full one on the overview, the compact one on every
// other tab, so the ship stays named while its loadouts or cargo are open.
const heroVisible = computed(() =>
  isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW),
);

// The full header belongs to the overview; the other tabs open on the compact
// one, so their own content starts higher.
const onOverview = computed(() => route.name === "hangar-vehicle-overview");

const sessionStore = useSessionStore();

const id = computed(() => route.params.id as string);

const { data: vehicle, ...asyncStatus } = useShowVehicle(id);

const vehicleName = computed(() => {
  if (!vehicle.value) return "";

  const nameParts = [vehicle.value.name || vehicle.value.model?.name];

  if (vehicle.value.serial) {
    nameParts.push(`(${vehicle.value.serial})`);
  }

  return nameParts.join(" ");
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "hangar" },
    label: t("nav.hangar.index"),
  },
  {
    to: { name: "hangar-vehicle", params: { id: route.params.id } },
    label: vehicleName.value,
  },
]);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" />
      <VehicleHero
        v-if="vehicle && heroVisible"
        :vehicle="vehicle"
        :compact="!onOverview"
      />
      <TabNavView
        v-if="vehicle"
        :routes="tabs"
        :authenticated="sessionStore.isAuthenticated"
        :horizontal="heroVisible"
      >
        <template #content>
          <router-view :vehicle="vehicle" />
        </template>
      </TabNavView>
    </template>
  </AsyncData>
</template>
