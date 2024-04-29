import type { RouteRecordRaw } from "vue-router";
import { routes as modelRoutes } from "@/admin/pages/models/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "models",
    component: () => import("@/admin/pages/models/index.vue"),
    meta: {
      title: "admin.models.index",
      icon: "fad fa-list",
    },
  },
  {
    path: "create/",
    name: "model-create",
    component: () => import("@/admin/pages/models/create.vue"),
    meta: {
      title: "admin.models.new",
      icon: "fad fa-plus",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/models/[id].vue"),
    children: modelRoutes,
    redirect: { name: modelRoutes[0].name },
    meta: {
      hide: true,
    },
  },
];
