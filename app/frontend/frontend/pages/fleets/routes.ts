import type { RouteRecordRaw } from "vue-router";
import { routes as fleetRoutes } from "@/frontend/pages/fleets/[slug]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "add/",
    name: "fleet-add",
    component: () => import("@/frontend/pages/fleets/add.vue"),
    meta: {
      needsAuthentication: true,
      title: "fleets.add",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "preview/",
    name: "fleet-preview",
    component: () => import("@/frontend/pages/fleets/preview.vue"),
    meta: {
      title: "fleets.preview",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "invites/",
    name: "fleet-invites",
    component: () => import("@/frontend/pages/fleets/invites.vue"),
    meta: {
      needsAuthentication: true,
      title: "fleets.invites",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "invites/:token/",
    name: "fleet-invite",
    component: () => import("@/frontend/pages/fleets/invite.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
    },
  },
  {
    path: ":slug/",
    component: () => import("@/frontend/pages/fleets/[slug].vue"),
    children: fleetRoutes,
    redirect: { name: fleetRoutes[0].name },
  },
];

export default routes;
