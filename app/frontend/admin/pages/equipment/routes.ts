import type { RouteRecordRaw } from "vue-router";
import { routes as equipmentRoutes } from "@/admin/pages/equipment/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-equipment",
    component: () => import("@/admin/pages/equipment/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["equipment"],
    },
  },
  {
    path: "create/",
    name: "admin-equipment-create",
    component: () => import("@/admin/pages/equipment/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      access: ["equipment"],
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/equipment/[id].vue"),
    children: equipmentRoutes,
    redirect: { name: equipmentRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      access: ["equipment"],
    },
  },
];
