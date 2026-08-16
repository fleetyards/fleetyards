import type { RouteRecordRaw } from "vue-router";

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
      feature: "ship_inventories",
    },
  },
];
