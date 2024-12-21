import type { RouteRecordRaw } from "vue-router";
import { routes as componentRoutes } from "@/admin/pages/components/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-components",
    component: () => import("@/admin/pages/components/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: "components",
    },
  },
  {
    path: "create/",
    name: "admin-component-create",
    component: () => import("@/admin/pages/components/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      access: "components",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/components/[id].vue"),
    children: componentRoutes,
    redirect: { name: componentRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      access: "components",
    },
  },
];
