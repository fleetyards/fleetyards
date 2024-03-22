import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "model",
    component: () => import("@/frontend/pages/ships/[slug]/index.vue"),
  },
  {
    path: "images/",
    name: "model-images",
    component: () => import("@/frontend/pages/ships/[slug]/images.vue"),
  },
  {
    path: "videos/",
    name: "model-videos",
    component: () => import("@/frontend/pages/ships/[slug]/videos.vue"),
  },
];
