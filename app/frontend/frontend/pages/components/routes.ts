import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "components",
    component: () => import("@/frontend/pages/components/index.vue"),
    meta: {
      title: "components.index",
      nav: "main",
    },
  },
  {
    path: ":slug/",
    name: "component",
    component: () => import("@/frontend/pages/components/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
