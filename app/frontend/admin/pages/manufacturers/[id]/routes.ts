import type { RouteRecordRaw } from "vue-router";
import { routes as manufacturerEditRoutes } from "@/admin/pages/manufacturers/[id]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit/",
    component: () => import("@/admin/pages/manufacturers/[id]/edit.vue"),
    children: manufacturerEditRoutes,
    redirect: { name: manufacturerEditRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-manufacturers",
    },
  },
];
