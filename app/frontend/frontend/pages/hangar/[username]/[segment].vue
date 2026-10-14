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
import {
  FeatureFlagName,
  useShowVehicle,
  useVehicleInventory,
  useVehicleLogEntries,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { checkFeatures } from "@/shared/utils/Access";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import {
  vehicleIdentifierFromSegment,
  vehicleSegment,
} from "@/frontend/utils/vehicleSegment";
import { routes as vehicleRoutes } from "@/frontend/pages/hangar/[username]/[segment]/routes";
import { useVehicleMeta } from "@/frontend/composables/useVehicleMeta";

const { t } = useI18n();
const { isFeatureEnabled } = useFeatures();

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

const router = useRouter();

const segment = computed(() => String(route.params.segment ?? ""));

// The route only matches a segment that leads with a serial or an id, so there
// is always one to look up.
const identifier = computed(
  () => vehicleIdentifierFromSegment(segment.value) ?? segment.value,
);

const { data: vehicle, ...asyncStatus } = useShowVehicle(identifier);

const wanted = computed(() => !!vehicle.value?.wanted);

const vehicleId = computed(() => vehicle.value?.id ?? "");

// The same queries the overview's cards run, so asking here costs nothing more.
const { data: logEntries } = useVehicleLogEntries(vehicleId, {
  query: { enabled: wanted },
});

const { data: inventory } = useVehicleInventory(vehicleId, {
  query: {
    enabled: computed(
      () => wanted.value && isFeatureEnabled(FeatureFlagName.SHIP_INVENTORIES),
    ),
  },
});

// A wishlist ship takes no new log entries or cargo, so these tabs only stay
// while there is something already in them to read.
const emptyOnWishlist = computed<Record<string, boolean>>(() => ({
  "hangar-vehicle-log": !logEntries.value?.length,
  "hangar-vehicle-cargo": !inventory.value?.entriesCount,
}));

// A tab behind a flag stays out of the bar entirely; its endpoints answer 403
// until the flag is on, so showing it would only offer a dead end.
const tabs = computed(() =>
  vehicleRoutes.filter(
    (tab) =>
      // A route reached from a tab rather than being one -- the cargo ledger is
      // the same hold, seen differently.
      tab.meta?.nav !== "hidden" &&
      checkFeatures(tab.meta?.feature, isFeatureEnabled) &&
      !(wanted.value && emptyOnWishlist.value[String(tab.name)]),
  ),
);

useVehicleMeta(vehicle);

// A renamed ship, a serial added later or a hand-typed address all land here;
// the address bar is put right once the vehicle is known.
watch(
  vehicle,
  (current) => {
    if (!current || !route.params.segment) return;

    const username =
      sessionStore.currentUser?.username ?? String(route.params.username);
    const canonical = vehicleSegment(current);

    if (canonical === segment.value && username === route.params.username) {
      return;
    }

    void router.replace({
      name: route.name,
      params: { ...route.params, username, segment: canonical },
      query: route.query,
      hash: route.hash,
    });
  },
  { immediate: true },
);

const vehicleName = computed(() => {
  if (!vehicle.value) return "";

  const nameParts = [vehicle.value.name || vehicle.value.model?.name];

  if (vehicle.value.serial) {
    nameParts.push(`(${vehicle.value.serial})`);
  }

  return nameParts.join(" ");
});

// The hero names the ship, so the trail only leads back to the hangar.
const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "hangar" },
    label: t("nav.hangar.index"),
  },
  ...(heroVisible.value
    ? []
    : [
        {
          to: {
            name: "hangar-vehicle",
            params: {
              username: route.params.username,
              segment: route.params.segment,
            },
          },
          label: vehicleName.value,
        },
      ]),
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
