import type { RouteRecordRaw } from "vue-router";
import { routes as componentEditRoutes } from "@/admin/pages/components/[id]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit/",
    component: () => import("@/admin/pages/components/[id]/edit.vue"),
    children: componentEditRoutes,
    redirect: { name: componentEditRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-components",
    },
  },
];
