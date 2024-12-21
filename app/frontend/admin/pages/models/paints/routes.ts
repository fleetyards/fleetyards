import type { RouteRecordRaw } from "vue-router";
import { routes as modelPaintRoutes } from "@/admin/pages/models/paints/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-model-paints",
    component: () => import("@/admin/pages/models/paints/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      title: "admin.modelPaints.index",
      icon: "fad fa-palette",
      access: "model_paints",
    },
  },
  {
    path: "create/",
    name: "admin-model-paint-create",
    component: () => import("@/admin/pages/models/paints/create.vue"),
    meta: {
      needsAuthentication: true,
      title: "admin.modelPaints.edit",
      nav: "hidden",
      activeRoute: "admin-model-paints",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/models/paints/[id].vue"),
    children: modelPaintRoutes,
    redirect: { name: modelPaintRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-model-paints",
    },
  },
];
