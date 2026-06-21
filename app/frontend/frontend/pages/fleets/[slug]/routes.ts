import type { RouteRecordRaw } from "vue-router";
import { routes as membersRoutes } from "@/frontend/pages/fleets/[slug]/members/routes";
import { routes as logisticsRoutes } from "@/frontend/pages/fleets/[slug]/logistics/routes";
import { routes as missionsRoutes } from "@/frontend/pages/fleets/[slug]/missions/routes";
import { routes as eventsRoutes } from "@/frontend/pages/fleets/[slug]/events/routes";
import { routes as settingsRoutes } from "@/frontend/pages/fleets/[slug]/settings/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet",
    component: () => import("@/frontend/pages/fleets/[slug]/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      customTitle: true,
    },
  },
  {
    path: "ships/",
    name: "fleet-ships",
    component: () => import("@/frontend/pages/fleets/[slug]/ships.vue"),
    meta: {
      backgroundImage: "bg-8",
      customTitle: true,
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
      customTitle: true,
    },
    redirect: {
      name: membersRoutes[0].name,
    },
    children: membersRoutes,
  },
  {
    path: "logistics/",
    name: "fleet-logistics-root",
    component: () => import("@/frontend/pages/fleets/[slug]/logistics.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      customTitle: true,
    },
    redirect: {
      name: logisticsRoutes[0].name,
    },
    children: logisticsRoutes,
  },
  {
    path: "missions/",
    name: "fleet-missions-root",
    component: () => import("@/frontend/pages/fleets/[slug]/missions.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      customTitle: true,
    },
    redirect: {
      name: missionsRoutes[0].name,
    },
    children: missionsRoutes,
  },
  {
    path: "events/",
    name: "fleet-events-root",
    component: () => import("@/frontend/pages/fleets/[slug]/events.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      customTitle: true,
    },
    redirect: {
      name: eventsRoutes[0].name,
    },
    children: eventsRoutes,
  },
  {
    path: "calendar/",
    name: "fleet-calendar",
    redirect: (to) => ({
      name: "fleet-events",
      params: { slug: to.params.slug },
      query: { view: "calendar" },
    }),
  },
  {
    path: "settings/",
    name: "fleet-settings",
    component: () => import("@/frontend/pages/fleets/[slug]/settings.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
      title: "fleets.settings.index",
      customTitle: true,
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
      backgroundImage: "bg-8",
      title: "fleets.stats",
      customTitle: true,
    },
  },
];
