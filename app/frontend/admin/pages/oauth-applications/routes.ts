import type { RouteRecordRaw } from "vue-router";
import { routes as oauthApplicationRoutes } from "@/admin/pages/oauth-applications/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-oauth-applications",
    component: () => import("@/admin/pages/oauth-applications/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["oauth_applications"],
    },
  },
  {
    path: "create/",
    name: "admin-oauth-application-create",
    component: () => import("@/admin/pages/oauth-applications/create.vue"),
    meta: {
      title: "admin.oauthApplications.new",
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-oauth-applications",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/oauth-applications/[id].vue"),
    children: oauthApplicationRoutes,
    redirect: { name: oauthApplicationRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-oauth-applications",
    },
  },
];
