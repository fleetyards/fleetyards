import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-model-modules",
    component: () => import("@/admin/pages/models/modules/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      title: "admin.modelModules.index",
      icon: "fad fa-puzzle",
      access: ["model_modules"],
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
    },
  },
];
