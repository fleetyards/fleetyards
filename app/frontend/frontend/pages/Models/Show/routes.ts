import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "model",
    component: () => import("@/frontend/pages/Models/Show/index.vue"),
  },
  {
    path: "images/",
    name: "model-images",
    component: () => import("@/frontend/pages/Models/Show/Images/index.vue"),
  },
  {
    path: "videos/",
    name: "model-videos",
    component: () => import("@/frontend/pages/Models/Show/Videos/index.vue"),
  },
];
