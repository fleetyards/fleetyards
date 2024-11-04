import type { RouteRecordRaw } from "vue-router";
import { routes as modelRoutes } from "@/admin/pages/models/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-models",
    component: () => import("@/admin/pages/models/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "create/",
    name: "admin-model-create",
    component: () => import("@/admin/pages/models/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/models/[id].vue"),
    children: modelRoutes,
    redirect: { name: modelRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
    },
  },
];
