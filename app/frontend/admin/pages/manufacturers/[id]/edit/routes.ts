import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-manufacturer-edit",
    component: () => import("@/admin/pages/manufacturers/[id]/edit/index.vue"),
    meta: {
      title: "admin.manufacturers.edit.index",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-manufacturers",
    },
  },
];
