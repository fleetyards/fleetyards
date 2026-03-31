import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "api-v1-schema",
    component: () => import("@/docs/pages/api/v1/index.vue"),
    meta: {
      title: "apiV1Schema",
      nav: "hidden",
    },
  },
  {
    path: "pagination/",
    name: "api-v1-pagination",
    component: () => import("@/docs/pages/api/v1/pagination.vue"),
    meta: {
      title: "apiV1Pagination",
      nav: "hidden",
    },
  },
];
