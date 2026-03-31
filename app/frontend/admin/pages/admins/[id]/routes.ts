import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-admin-edit",
    component: () => import("@/admin/pages/admins/[id]/edit.vue"),
    meta: {
      title: "admin.admins.edit",
      activeRoute: "admin-admins",
      needsAuthentication: true,
    },
  },
];
