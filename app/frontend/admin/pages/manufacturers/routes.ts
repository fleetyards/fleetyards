import type { RouteRecordRaw } from "vue-router";
import { routes as manufacturerRoutes } from "@/admin/pages/manufacturers/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-manufacturers",
    component: () => import("@/admin/pages/manufacturers/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: "manufacturers",
    },
  },
  {
    path: "create/",
    name: "admin-manufacturer-create",
    component: () => import("@/admin/pages/manufacturers/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-manufacturers",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/manufacturers/[id].vue"),
    children: manufacturerRoutes,
    redirect: { name: manufacturerRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-manufacturers",
    },
  },
];
