import type { RouteRecordRaw } from "vue-router";
import { routes as equipmentEditRoutes } from "@/admin/pages/equipment/[id]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit/",
    component: () => import("@/admin/pages/equipment/[id]/edit.vue"),
    children: equipmentEditRoutes,
    redirect: { name: equipmentEditRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-equipment",
    },
  },
];
