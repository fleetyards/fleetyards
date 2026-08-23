import type { RouteRecordRaw } from "vue-router";
import { routes as oauthApplicationRoutes } from "@/frontend/pages/settings/oauth-applications/[id]/routes";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "settings-oauth-applications",
    component: () =>
      import("@/frontend/pages/settings/oauth-applications/index.vue"),
    strict: true,
    meta: {
      title: "settings.oauthApplications",
      needsAuthentication: true,
      feature: FeatureFlagName.OAUTH_APPLICATIONS,
    },
  },
  {
    path: "create/",
    name: "settings-oauth-application-create",
    component: () =>
      import("@/frontend/pages/settings/oauth-applications/create.vue"),
    meta: {
      title: "settings.oauthApplications",
      needsAuthentication: true,
      feature: FeatureFlagName.OAUTH_APPLICATIONS,
    },
  },
  {
    path: ":id/",
    component: () =>
      import("@/frontend/pages/settings/oauth-applications/[id].vue"),
    children: oauthApplicationRoutes,
    redirect: { name: oauthApplicationRoutes[0].name },
    meta: {
      needsAuthentication: true,
      feature: FeatureFlagName.OAUTH_APPLICATIONS,
    },
  },
];
