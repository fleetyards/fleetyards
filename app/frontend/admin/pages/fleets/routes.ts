import type { RouteRecordRaw } from "vue-router";
import { routes as fleetRoutes } from "@/admin/pages/fleets/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-fleets",
    component: () => import("@/admin/pages/fleets/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["fleets"],
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/fleets/[id].vue"),
    children: fleetRoutes,
    redirect: { name: fleetRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-fleets",
    },
  },
];
