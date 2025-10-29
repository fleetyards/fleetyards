import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-component-edit",
    component: () => import("@/admin/pages/components/[id]/edit.vue"),
    meta: {
      title: "admin.components.edit",
      activeRoute: "components",
      needsAuthentication: true,
    },
  },
];
