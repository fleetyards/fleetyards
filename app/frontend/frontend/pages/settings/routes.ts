import type { RouteRecordRaw } from "vue-router";
import { routes as securityRoutes } from "./security/routes";

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
    path: "security/",
    name: "settings-security",
    component: () => import("@/frontend/pages/settings/security.vue"),
    meta: {
      title: "settings.security",
      needsAuthentication: true,
    },
    redirect: {
      name: "settings-security-status",
    },
    children: securityRoutes,
  },
];
