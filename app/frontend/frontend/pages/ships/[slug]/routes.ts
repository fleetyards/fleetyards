import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "ship",
    component: () => import("@/frontend/pages/ships/[slug]/index.vue"),
  },
  {
    path: "images/",
    name: "ship-images",
    component: () => import("@/frontend/pages/ships/[slug]/images.vue"),
  },
  {
    path: "videos/",
    name: "ship-videos",
    component: () => import("@/frontend/pages/ships/[slug]/videos.vue"),
  },
];
