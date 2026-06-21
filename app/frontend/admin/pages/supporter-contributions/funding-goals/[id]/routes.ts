import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-funding-goal-edit",
    component: () =>
      import("@/admin/pages/supporter-contributions/funding-goals/[id]/edit.vue"),
    meta: {
      title: "admin.fundingGoals.edit",
      activeRoute: "admin-supporter-contributions",
      needsAuthentication: true,
    },
  },
];
