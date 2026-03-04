import type { RouteRecordRaw } from "vue-router";
import { routes as vehicleRoutes } from "@/admin/pages/vehicles/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-vehicles",
    component: () => import("@/admin/pages/vehicles/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["vehicles"],
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/vehicles/[id].vue"),
    children: vehicleRoutes,
    redirect: { name: vehicleRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-vehicles",
    },
  },
];
