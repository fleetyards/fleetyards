import type { RouteRecordRaw } from "vue-router";
import SecurityRoutes from "./Security/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "profile/",
    name: "settings-profile",
    component: () => import("@/frontend/pages/Settings/Profile/index.vue"),
    meta: {
      title: "settings.index",
      needsAuthentication: true,
    },
  },
  {
    path: "account/",
    name: "settings-account",
    component: () => import("@/frontend/pages/Settings/Account/index.vue"),
    meta: {
      title: "settings.account",
      needsAuthentication: true,
    },
  },
  {
    path: "notifications/",
    name: "settings-notifications",
    component: () =>
      import("@/frontend/pages/Settings/Notifications/index.vue"),
    meta: {
      title: "settings.notifications",
      needsAuthentication: true,
    },
  },
  {
    path: "hangar/",
    name: "settings-hangar",
    component: () => import("@/frontend/pages/Settings/Hangar/index.vue"),
    meta: {
      title: "settings.hangar",
      needsAuthentication: true,
    },
  },
  {
    path: "security/",
    name: "settings-security",
    component: () =>
      import("@/frontend/pages/Settings/Security/routerView.vue"),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: "settings-security-status",
    },
    children: SecurityRoutes,
  },
];

export default routes;
