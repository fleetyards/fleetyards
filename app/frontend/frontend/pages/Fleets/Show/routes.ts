import type { RouteRecordRaw } from "vue-router";
import { routes as settingsRoutes } from "@/frontend/pages/Fleets/Show/Settings/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet",
    component: () => import("@/frontend/pages/Fleets/Show/index.vue"),
    meta: {
      backgroundImage: "bg-8",
    },
  },
  {
    path: "ships/",
    name: "fleet-ships",
    component: () => import("@/frontend/pages/Fleets/Show/Ships/index.vue"),
    meta: {
      backgroundImage: "bg-8",
    },
  },
  {
    path: "fleetchart/",
    name: "fleet-fleetchart",
    redirect: {
      name: "fleet-ships",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "members/",
    name: "fleet-members",
    component: () => import("@/frontend/pages/Fleets/Show/Members/index.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
    },
  },
  {
    path: "settings/",
    name: "fleet-settings",
    component: () =>
      import("@/frontend/pages/Fleets/Show/Settings/routerView.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
    },
    redirect: {
      name: "fleet-settings-fleet",
    },
    children: settingsRoutes,
  },
  {
    path: "stats/",
    name: "fleet-stats",
    component: () => import("@/frontend/pages/Fleets/Show/Stats/index.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
    },
  },
];
