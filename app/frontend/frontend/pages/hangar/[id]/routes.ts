import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
  {
    path: "overview/",
    name: "hangar-vehicle-overview",
    component: () => import("@/frontend/pages/hangar/[id]/overview.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.vehicleOverview",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.VEHICLE_OVERVIEW,
    },
  },
  {
    path: "loadouts/",
    name: "hangar-vehicle-loadouts",
    component: () => import("@/frontend/pages/hangar/[id]/loadouts.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.vehicleLoadouts",
      backgroundImage: "bg-5",
      customTitle: true,
    },
  },
  {
    path: "log/",
    name: "hangar-vehicle-log",
    component: () => import("@/frontend/pages/hangar/[id]/log.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.vehicleLog",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.VEHICLE_OVERVIEW,
    },
  },
  {
    path: "cargo/",
    name: "hangar-vehicle-cargo",
    component: () => import("@/frontend/pages/hangar/[id]/cargo.vue"),
    meta: {
      mobileBack: true,
      needsAuthentication: true,
      title: "hangar.vehicleCargo",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.SHIP_INVENTORIES,
    },
  },
  {
    // Was a route of its own; the view moved into the query so switching to it
    // keeps the page. The path stays so shared links resolve.
    path: "cargo/transactions/",
    redirect: (to) => ({
      name: "hangar-vehicle-cargo",
      params: to.params,
      query: { ...to.query, tab: "log" },
    }),
  },
];
