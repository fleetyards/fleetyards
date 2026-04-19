import type { RouteRecordRaw } from "vue-router";
import { routes as modelRoutes } from "@/admin/pages/models/[id]/routes";
import { routes as modelModulesRoutes } from "@/admin/pages/models/modules/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-models",
    component: () => import("@/admin/pages/models/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      title: "admin.models.index",
      icon: "fa-duotone fa-list",
      mobileNav: 1,
      access: ["models"],
    },
  },
  {
    path: "modules/",
    component: () => import("@/admin/pages/models.vue"),
    children: modelModulesRoutes,
    redirect: { name: modelModulesRoutes[0].name },
    meta: {
      needsAuthentication: true,
      title: "admin.modelModules.index",
      icon: "fa-duotone fa-puzzle",
      nav: "hidden",
      activeRoute: "admin-models",
      access: ["model_modules"],
    },
  },
  {
    path: "create/",
    name: "admin-model-create",
    component: () => import("@/admin/pages/models/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-models",
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
      activeRoute: "admin-models",
    },
  },
];
