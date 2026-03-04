import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-fleet-edit",
    component: () => import("@/admin/pages/fleets/[id]/edit.vue"),
    meta: {
      title: "admin.fleets.edit",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
];
