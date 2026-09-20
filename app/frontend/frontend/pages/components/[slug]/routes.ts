import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "component",
    component: () => import("@/frontend/pages/components/[slug]/index.vue"),
    meta: {
      customTitle: true,
    },
  },
  {
    path: "history/",
    name: "component-history",
    component: () => import("@/frontend/pages/components/[slug]/history.vue"),
    meta: {
      customTitle: true,
    },
  },
];
