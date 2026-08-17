import type { RouteRecordRaw } from "vue-router";
import { routes as commodityEditRoutes } from "@/admin/pages/commodities/[id]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit/",
    component: () => import("@/admin/pages/commodities/[id]/edit.vue"),
    children: commodityEditRoutes,
    redirect: { name: commodityEditRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-commodities",
    },
  },
];
