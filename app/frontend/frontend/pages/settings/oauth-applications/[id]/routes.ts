import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "settings-oauth-application",
    component: () =>
      import("@/frontend/pages/settings/oauth-applications/[id]/index.vue"),
    meta: {
      title: "settings.oauthApplications",
      needsAuthentication: true,
      feature: FeatureFlagName.OAUTH_APPLICATIONS,
    },
  },
  {
    path: "edit/",
    name: "settings-oauth-application-edit",
    component: () =>
      import("@/frontend/pages/settings/oauth-applications/[id]/edit.vue"),
    meta: {
      title: "settings.oauthApplications",
      needsAuthentication: true,
      feature: FeatureFlagName.OAUTH_APPLICATIONS,
    },
  },
];
