import type { RouteRecordRaw } from "vue-router";
import { routes as vehicleRoutes } from "@/frontend/pages/hangar/[id]/routes";
import { routes as publicHangarRoutes } from "@/frontend/pages/hangar/[username]/routes";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "hangar",
    component: () => import("@/frontend/pages/hangar/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.index",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "wishlist/",
    name: "hangar-wishlist",
    component: () => import("@/frontend/pages/hangar/wishlist.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.wishlist",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "preview/",
    name: "hangar-preview",
    component: () => import("@/frontend/pages/hangar/preview.vue"),
    meta: {
      title: "hangar.preview",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "fleetchart/",
    name: "hangar-fleetchart",
    redirect: {
      name: "hangar",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "transfers/",
    name: "hangar-transfers",
    component: () => import("@/frontend/pages/hangar/transfers.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.transfers",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.INVENTORY_TRANSFERS,
    },
  },
  {
    path: "inventories/",
    name: "hangar-inventories",
    component: () => import("@/frontend/pages/hangar/inventories/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    // Not `inventories/transactions`: an inventory slugged "transactions" would
    // shadow it.
    path: "transactions/",
    name: "hangar-transactions",
    component: () => import("@/frontend/pages/hangar/inventories/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    path: "inventories/:inventory/",
    name: "hangar-inventory",
    component: () =>
      import("@/frontend/pages/hangar/inventories/[inventory].vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    // The ledger is a place you can link somebody to, so it is a route.
    path: "inventories/:inventory/transactions/",
    name: "hangar-inventory-transactions",
    component: () =>
      import("@/frontend/pages/hangar/inventories/[inventory].vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    path: "inventories/:inventory/items/:item/",
    name: "hangar-inventory-item",
    component: () =>
      import("@/frontend/pages/hangar/inventories/[inventory]/[item].vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.inventories",
      backgroundImage: "bg-5",
      feature: FeatureFlagName.HANGAR_INVENTORIES,
    },
  },
  {
    path: "imports/",
    name: "hangar-imports",
    component: () => import("@/frontend/pages/hangar/imports.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.imports",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "stats/",
    name: "hangar-stats",
    component: () => import("@/frontend/pages/hangar/stats.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.stats",
      backgroundImage: "bg-5",
    },
  },
  {
    path: ":username/",
    component: () => import("@/frontend/pages/hangar/[username].vue"),
    children: publicHangarRoutes,
    redirect: { name: publicHangarRoutes[0].name },
  },
  // Outside the vehicle's tab shell on purpose: everything under it becomes a
  // tab, and a single cargo position is a page you drill into rather than a
  // fifth place to stand. Same shape as /hangar/inventories/:inventory/:item.
  {
    path: ":id/cargo/:item/",
    name: "hangar-vehicle-cargo-item",
    component: () => import("@/frontend/pages/hangar/[id]/cargo/[item].vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.vehicleCargo",
      backgroundImage: "bg-5",
      customTitle: true,
      feature: FeatureFlagName.SHIP_INVENTORIES,
    },
  },
  {
    path: ":id/",
    component: () => import("@/frontend/pages/hangar/[id].vue"),
    children: vehicleRoutes,
    redirect: { name: vehicleRoutes[0].name },
    meta: {
      needsAuthentication: true,
    },
  },
];
