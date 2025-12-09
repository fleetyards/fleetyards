import type { RouteRecordRaw } from "vue-router";
import { routes as modelRoutes } from "@/admin/pages/models/[id]/routes";
import { routes as modelModulesRoutes } from "@/admin/pages/models/modules/routes";
import { routes as modelPaintsRoutes } from "@/admin/pages/models/paints/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-models",
    component: () => import("@/admin/pages/models/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      title: "admin.models.index",
      icon: "fad fa-list",
      mobileNav: 1,
      access: ["models"],
    },
  },
  {
    path: "create/",
    name: "admin-model-create",
    component: () => import("@/admin/pages/models/create.vue"),
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-models",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/models/[id].vue"),
    children: modelRoutes,
    redirect: { name: modelRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-models",
    },
  },
];
