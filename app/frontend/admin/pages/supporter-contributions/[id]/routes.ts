import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-supporter-contribution-edit",
    component: () =>
      import("@/admin/pages/supporter-contributions/[id]/edit.vue"),
    meta: {
      title: "admin.supporterContributions.edit",
      activeRoute: "admin-supporter-contributions",
      needsAuthentication: true,
    },
  },
];
