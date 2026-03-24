import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-component-edit",
    component: () => import("@/admin/pages/components/[id]/edit/index.vue"),
    meta: {
      title: "admin.components.edit.index",
      customTitle: true,
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-components",
    },
  },
  {
    path: "prices/",
    name: "admin-component-edit-prices",
    component: () => import("@/admin/pages/components/[id]/edit/prices.vue"),
    meta: {
      title: "admin.components.edit.prices",
      customTitle: true,
      activeRoute: "admin-components",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
];
