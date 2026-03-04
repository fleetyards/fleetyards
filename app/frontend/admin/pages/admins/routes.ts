import type { RouteRecordRaw } from "vue-router";
import { routes as adminUserRoutes } from "@/admin/pages/admins/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-admins",
    component: () => import("@/admin/pages/admins/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["admins"],
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/admins/[id].vue"),
    children: adminUserRoutes,
    redirect: { name: adminUserRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-admins",
    },
  },
];
