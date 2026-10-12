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
import VehicleHeroBar from "@/frontend/components/Vehicles/HeroBar/index.vue";
import { useIntersectionObserver } from "@vueuse/core";
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

// The overview's header, carried across every tab so the ship stays in view
// while its loadouts or cargo are open.
const heroVisible = computed(() =>
  isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW),
);

// The full header belongs to the overview. Once it scrolls away, and on every
// other tab from the start, a compact bar keeps the ship in view and pins the
// tabs under it.
const onOverview = computed(() => route.name === "hangar-vehicle-overview");

const heroEl = ref<InstanceType<typeof VehicleHero> | null>(null);
const heroInView = ref(true);

useIntersectionObserver(
  () => heroEl.value?.$el as HTMLElement | undefined,
  ([entry]) => {
    heroInView.value = !!entry?.isIntersecting;
  },
);

const barVisible = computed(
  () => heroVisible.value && (!onOverview.value || !heroInView.value),
);

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
        v-if="vehicle && heroVisible && onOverview"
        ref="heroEl"
        :vehicle="vehicle"
      />
      <div
        v-if="vehicle && heroVisible"
        class="vehicle-sticky-bar"
        :class="{
          'vehicle-sticky-bar--overlay': onOverview,
          'vehicle-sticky-bar--visible': barVisible,
        }"
        :aria-hidden="!barVisible"
        :inert="!barVisible"
      >
        <div class="vehicle-sticky-bar__inner">
          <VehicleHeroBar :vehicle="vehicle" />
        </div>
      </div>
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

<style lang="scss" scoped>
/*
 * Pinned to the top of the page. On the other tabs it is the header, so it
 * takes its own height in the flow. On the overview the full header is the
 * header, and the bar floats over the page instead -- no height of its own, so
 * sliding it in moves nothing underneath and cannot flip the observer that
 * shows it.
 */
.vehicle-sticky-bar {
  position: sticky;
  top: 0;
  z-index: 900;
  height: var(--vehicle-hero-bar-h, 64px);
  margin: 0 -15px 20px;

  &__inner {
    height: var(--vehicle-hero-bar-h, 64px);
    padding: 0 15px;
    border-bottom: 1px solid var(--color-edge-soft);
    background: rgb(10 12 14 / 0.92);
    backdrop-filter: blur(8px);
  }

  &--overlay {
    height: 0;
    margin-bottom: 0;

    .vehicle-sticky-bar__inner {
      opacity: 0;
      transform: translateY(-100%);
      transition:
        transform 0.2s ease,
        opacity 0.2s ease;
    }
  }

  &--overlay.vehicle-sticky-bar--visible .vehicle-sticky-bar__inner {
    opacity: 1;
    transform: none;
  }

  @media (prefers-reduced-motion: reduce) {
    &--overlay .vehicle-sticky-bar__inner {
      transition: none;
    }
  }
}
</style>
