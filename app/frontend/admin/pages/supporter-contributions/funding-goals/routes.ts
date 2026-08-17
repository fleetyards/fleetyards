import type { RouteRecordRaw } from "vue-router";
import { routes as fundingGoalRoutes } from "@/admin/pages/supporter-contributions/funding-goals/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-funding-goals",
    component: () =>
      import("@/admin/pages/supporter-contributions/funding-goals/index.vue"),
    strict: true,
    meta: {
      title: "admin.fundingGoals.index",
      needsAuthentication: true,
      access: ["supporters"],
      activeRoute: "admin-supporter-contributions",
    },
  },
  {
    path: "create/",
    name: "admin-funding-goal-create",
    component: () =>
      import("@/admin/pages/supporter-contributions/funding-goals/create.vue"),
    meta: {
      title: "admin.fundingGoals.new",
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-supporter-contributions",
    },
  },
  {
    path: ":id/",
    component: () =>
      import("@/admin/pages/supporter-contributions/funding-goals/[id].vue"),
    children: fundingGoalRoutes,
    redirect: { name: fundingGoalRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-supporter-contributions",
    },
  },
];
