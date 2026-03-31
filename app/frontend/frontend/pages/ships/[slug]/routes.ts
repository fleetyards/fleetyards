import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "ship",
    component: () => import("@/frontend/pages/ships/[slug]/index.vue"),
    meta: {
      customTitle: true,
    },
  },
  {
    path: "images/",
    name: "ship-images",
    component: () => import("@/frontend/pages/ships/[slug]/images.vue"),
    meta: {
      customTitle: true,
    },
  },
  {
    path: "videos/",
    name: "ship-videos",
    component: () => import("@/frontend/pages/ships/[slug]/videos.vue"),
    meta: {
      customTitle: true,
    },
  },
  {
    path: "viewer/",
    name: "ship-viewer",
    component: () => import("@/frontend/pages/ships/[slug]/viewer.vue"),
    meta: {
      customTitle: true,
    },
  },
];
