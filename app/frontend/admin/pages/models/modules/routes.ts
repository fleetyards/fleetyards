import type { RouteRecordRaw } from "vue-router";
import { routes as modelModuleRoutes } from "@/admin/pages/models/modules/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-model-modules",
    component: () => import("@/admin/pages/models/modules/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      title: "admin.modelModules.index",
      icon: "fa-duotone fa-puzzle",
      access: ["model_modules"],
      activeRoute: "admin-models",
    },
  },
  {
    path: "packages/",
    name: "admin-model-modules-packages",
    component: () => import("@/admin/pages/models/modules/packages.vue"),
    meta: {
      needsAuthentication: true,
      title: "admin.modelModulePackages.index",
      nav: "hidden",
      activeRoute: "admin-models",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/models/modules/[id].vue"),
    children: modelModuleRoutes,
    redirect: { name: modelModuleRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-model-modules",
    },
  },
];
