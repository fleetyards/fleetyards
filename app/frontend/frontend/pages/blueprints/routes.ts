import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "blueprints",
    component: () => import("@/frontend/pages/blueprints/index.vue"),
    meta: {
      title: "blueprints.index",
      nav: "main",
    },
  },
  {
    path: ":slug/",
    name: "blueprint",
    component: () => import("@/frontend/pages/blueprints/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
