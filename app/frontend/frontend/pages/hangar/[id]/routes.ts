import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
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
    path: "cargo/",
    name: "hangar-vehicle-cargo",
    component: () => import("@/frontend/pages/hangar/[id]/cargo.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.vehicleCargo",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.SHIP_INVENTORIES,
    },
  },
];
