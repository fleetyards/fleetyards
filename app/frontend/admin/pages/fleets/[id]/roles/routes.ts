import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "roles/:roleId",
    name: "admin-fleet-role",
    component: () => import("@/admin/pages/fleets/[id]/roles/[roleId].vue"),
    meta: {
      title: "admin.fleets.role",
      activeRoute: "admin-fleets",
      activeTab: "admin-fleet-roles",
      needsAuthentication: true,
    },
  },
];
