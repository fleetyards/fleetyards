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
  {
    path: "images/",
    name: "admin-model-images",
    component: () => import("@/admin/pages/models/[id]/images.vue"),
    meta: {
      title: "admin.models.images",
      activeRoute: "admin-models",
      needsAuthentication: true,
    },
  },
  {
    path: "videos/",
    name: "admin-model-videos",
    component: () => import("@/admin/pages/models/[id]/videos.vue"),
    meta: {
      title: "admin.models.videos",
      activeRoute: "admin-models",
      needsAuthentication: true,
    },
  },
  {
    path: "prices/",
    name: "admin-model-prices",
    component: () => import("@/admin/pages/models/[id]/prices.vue"),
    meta: {
      title: "admin.models.prices",
      activeRoute: "admin-models",
      needsAuthentication: true,
    },
  },
];
