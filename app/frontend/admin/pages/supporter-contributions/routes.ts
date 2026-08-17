import type { RouteRecordRaw } from "vue-router";
import { routes as supporterContributionRoutes } from "@/admin/pages/supporter-contributions/[id]/routes";
import { routes as fundingGoalsRoutes } from "@/admin/pages/supporter-contributions/funding-goals/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-supporter-contributions",
    component: () => import("@/admin/pages/supporter-contributions/index.vue"),
    strict: true,
    meta: {
      title: "admin.supporterContributions.index",
      needsAuthentication: true,
      access: ["supporters"],
    },
  },
  {
    path: "create/",
    name: "admin-supporter-contribution-create",
    component: () => import("@/admin/pages/supporter-contributions/create.vue"),
    meta: {
      title: "admin.supporterContributions.new",
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-supporter-contributions",
    },
  },
  {
    path: "funding-goals/",
    component: () =>
      import("@/admin/pages/supporter-contributions/funding-goals.vue"),
    children: fundingGoalsRoutes,
    redirect: { name: fundingGoalsRoutes[0].name },
    meta: {
      needsAuthentication: true,
      access: ["supporters"],
      nav: "hidden",
      activeRoute: "admin-supporter-contributions",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/supporter-contributions/[id].vue"),
    children: supporterContributionRoutes,
    redirect: { name: supporterContributionRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-supporter-contributions",
    },
  },
];
