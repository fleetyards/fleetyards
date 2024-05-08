import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-model-edit",
    component: () => import("@/admin/pages/models/[id]/edit.vue"),
    meta: {
      title: "admin.models.edit",
      activeRoute: "models",
      needsAuthentication: true,
    },
  },
  {
    path: "images/",
    name: "admin-model-images",
    component: () => import("@/admin/pages/models/[id]/images.vue"),
    meta: {
      title: "admin.models.images",
      activeRoute: "models",
      needsAuthentication: true,
    },
  },
  {
    path: "videos/",
    name: "admin-model-videos",
    component: () => import("@/admin/pages/models/[id]/videos.vue"),
    meta: {
      title: "admin.models.videos",
      activeRoute: "models",
      needsAuthentication: true,
    },
  },
  {
    path: "prices/",
    name: "admin-model-prices",
    component: () => import("@/admin/pages/models/[id]/prices.vue"),
    meta: {
      title: "admin.models.prices",
      activeRoute: "models",
      needsAuthentication: true,
    },
  },
];
