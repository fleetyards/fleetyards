import type { RouteRecordRaw } from "vue-router";
import { routes as userRoutes } from "@/admin/pages/users/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-users",
    component: () => import("@/admin/pages/users/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/users/[id].vue"),
    children: userRoutes,
    redirect: { name: userRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
    },
  },
];
