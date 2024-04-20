import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-model",
    component: () => import("@/admin/pages/models/[id]/index.vue"),
    meta: {
      title: "admin.models.detail",
    },
  },
  {
    path: "edit",
    name: "admin-model-edit",
    component: () => import("@/admin/pages/models/[id]/edit.vue"),
    meta: {
      title: "admin.models.edit",
    },
  },
  {
    path: "images/",
    name: "admin-model-images",
    component: () => import("@/admin/pages/models/[id]/images.vue"),
    meta: {
      title: "admin.models.images",
    },
  },
  {
    path: "videos/",
    name: "admin-model-videos",
    component: () => import("@/admin/pages/models/[id]/videos.vue"),
    meta: {
      title: "admin.models.videos",
    },
  },
  {
    path: "prices/",
    name: "admin-model-prices",
    component: () => import("@/admin/pages/models/[id]/prices.vue"),
    meta: {
      title: "admin.models.prices",
    },
  },
];
