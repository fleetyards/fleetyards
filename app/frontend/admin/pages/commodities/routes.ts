import type { RouteRecordRaw } from "vue-router";
import { routes as commodityRoutes } from "@/admin/pages/commodities/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-commodities",
    component: () => import("@/admin/pages/commodities/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["commodities"],
    },
  },
  {
    path: "create/",
    name: "admin-commodity-create",
    component: () => import("@/admin/pages/commodities/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      access: ["commodities"],
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/commodities/[id].vue"),
    children: commodityRoutes,
    redirect: { name: commodityRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      access: ["commodities"],
    },
  },
];
