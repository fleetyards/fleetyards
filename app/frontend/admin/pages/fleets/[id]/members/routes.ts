import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "members/:memberId/edit",
    name: "admin-fleet-member-edit",
    component: () =>
      import("@/admin/pages/fleets/[id]/members/[memberId]/edit.vue"),
    meta: {
      title: "admin.fleets.memberEdit",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
];
