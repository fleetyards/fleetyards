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
  {
    path: "cargo/transactions/",
    name: "hangar-vehicle-cargo-transactions",
    component: () => import("@/frontend/pages/hangar/[id]/cargo.vue"),
    meta: {
      // Reached from the Cargo tab, not a tab of its own: the ledger is one of
      // two views of the same hold, switched by the control above the table.
      // `activeTab` is what keeps Cargo lit while it is open.
      nav: "hidden",
      activeTab: "hangar-vehicle-cargo",
      needsAuthentication: true,
      title: "hangar.vehicleCargo",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.SHIP_INVENTORIES,
    },
  },
];
