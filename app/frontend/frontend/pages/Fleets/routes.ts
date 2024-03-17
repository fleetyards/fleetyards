import type { RouteRecordRaw } from "vue-router";
import { routes as fleetRoutes } from "@/frontend/pages/Fleets/Show/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "add/",
    name: "fleet-add",
    component: () => import("@/frontend/pages/Fleets/Add/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "fleets.add",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "preview/",
    name: "fleet-preview",
    component: () => import("@/frontend/pages/Fleets/Preview/index.vue"),
    meta: {
      title: "fleets.preview",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "invites/",
    name: "fleet-invites",
    component: () => import("@/frontend/pages/Fleets/Invites/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "fleets.invites",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "invites/:token/",
    name: "fleet-invite",
    component: () => import("@/frontend/pages/Fleets/Invite/index.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
    },
  },
  {
    path: ":slug/",
    component: () => import("@/frontend/pages/Fleets/Show/routerView.vue"),
    children: fleetRoutes,
    redirect: { name: fleetRoutes[0].name },
  },
];

export default routes;
