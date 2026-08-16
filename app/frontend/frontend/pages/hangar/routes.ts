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
