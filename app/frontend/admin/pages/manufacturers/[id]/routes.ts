import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-manufacturer-edit",
    component: () => import("@/admin/pages/manufacturers/[id]/edit.vue"),
    meta: {
      title: "admin.manufacturers.edit",
      activeRoute: "admin-manufacturers",
      needsAuthentication: true,
    },
  },
];
