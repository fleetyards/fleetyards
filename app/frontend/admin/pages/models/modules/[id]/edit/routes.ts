import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-model-module-edit",
    component: () =>
      import("@/admin/pages/models/modules/[id]/edit/index.vue"),
    meta: {
      title: "admin.modelModules.edit.index",
      customTitle: true,
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-model-modules",
    },
  },
  {
    path: "models/",
    name: "admin-model-module-edit-models",
    component: () =>
      import("@/admin/pages/models/modules/[id]/edit/models.vue"),
    meta: {
      title: "admin.modelModules.edit.models",
      customTitle: true,
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-model-modules",
    },
  },
  {
    path: "prices/",
    name: "admin-model-module-edit-prices",
    component: () =>
      import("@/admin/pages/models/modules/[id]/edit/prices.vue"),
    meta: {
      title: "admin.modelModules.edit.prices",
      customTitle: true,
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-model-modules",
    },
  },
];
