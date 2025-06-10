import type { RouteRecordRaw } from "vue-router";
import { routes as settingsRoutes } from "@/frontend/pages/fleets/[slug]/settings/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet",
    component: () => import("@/frontend/pages/fleets/[slug]/index.vue"),
    meta: {
      backgroundImage: "bg-8",
    },
  },
  {
    path: "ships/",
    name: "fleet-ships",
    component: () => import("@/frontend/pages/fleets/[slug]/ships.vue"),
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
    component: () => import("@/frontend/pages/fleets/[slug]/members.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      quickSearch: "searchCont",
    },
  },
  {
    path: "settings/",
    name: "fleet-settings",
    component: () => import("@/frontend/pages/fleets/[slug]/settings.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      title: "fleets.settings.index",
    },
    redirect: {
      name: settingsRoutes[0].name,
    },
    children: settingsRoutes,
  },
  {
    path: "stats/",
    name: "fleet-stats",
    component: () => import("@/frontend/pages/fleets/[slug]/stats.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      title: "fleets.stats",
    },
  },
];
