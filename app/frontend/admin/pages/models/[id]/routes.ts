import type { RouteRecordRaw } from "vue-router";
import { routes as modelEditRoutes } from "@/admin/pages/models/[id]/edit/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit/",
    component: () => import("@/admin/pages/models/[id]/edit.vue"),
    children: modelEditRoutes,
    redirect: { name: modelEditRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-models",
    },
  },
];
