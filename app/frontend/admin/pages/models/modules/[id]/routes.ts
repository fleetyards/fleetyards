import type { RouteRecordRaw } from "vue-router";
import { routes as modelModuleEditRoutes } from "@/admin/pages/models/modules/[id]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit/",
    component: () => import("@/admin/pages/models/modules/[id]/edit.vue"),
    children: modelModuleEditRoutes,
    redirect: { name: modelModuleEditRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-model-modules",
    },
  },
];
