import type { RouteRecordRaw } from "vue-router";
import { routes as securityRoutes } from "./security/routes";
import { routes as oauthApplicationRoutes } from "./oauth-applications/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "profile/",
    name: "settings-profile",
    component: () => import("@/frontend/pages/settings/profile.vue"),
    meta: {
      title: "settings.profile",
      needsAuthentication: true,
    },
  },
  {
    path: "account/",
    name: "settings-account",
    component: () => import("@/frontend/pages/settings/account.vue"),
    meta: {
      title: "settings.account",
      needsAuthentication: true,
      needsSecurityConfirm: true,
    },
  },
  {
    path: "notifications/",
    name: "settings-notifications",
    component: () => import("@/frontend/pages/settings/notifications.vue"),
    meta: {
      title: "settings.notifications",
      needsAuthentication: true,
    },
  },
  {
    path: "hangar/",
    name: "settings-hangar",
    component: () => import("@/frontend/pages/settings/hangar.vue"),
    meta: {
      title: "settings.hangar",
      needsAuthentication: true,
    },
  },
  {
    path: "features/",
    name: "settings-features",
    component: () => import("@/frontend/pages/settings/features.vue"),
    meta: {
      title: "settings.features",
      needsAuthentication: true,
    },
  },
  {
    path: "oauth-applications/",
    component: () => import("@/frontend/pages/settings/oauth-applications.vue"),
    meta: {
      title: "settings.oauthApplications",
      needsAuthentication: true,
      feature: "oauth-applications",
    },
    redirect: {
      name: "settings-oauth-applications",
    },
    children: oauthApplicationRoutes,
  },
  {
    path: "security/",
    component: () => import("@/frontend/pages/settings/security.vue"),
    meta: {
      title: "settings.security",
      needsAuthentication: true,
    },
    redirect: {
      name: "settings-security",
    },
    children: securityRoutes,
  },
];
