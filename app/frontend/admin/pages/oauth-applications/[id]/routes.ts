import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-oauth-application-edit",
    component: () => import("@/admin/pages/oauth-applications/[id]/edit.vue"),
    meta: {
      title: "admin.oauthApplications.edit",
      activeRoute: "admin-oauth-applications",
      needsAuthentication: true,
    },
  },
];
