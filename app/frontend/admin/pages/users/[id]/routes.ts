import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-user-edit",
    component: () => import("@/admin/pages/users/[id]/edit.vue"),
    meta: {
      title: "admin.users.edit",
      activeRoute: "users",
      needsAuthentication: true,
    },
  },
];
