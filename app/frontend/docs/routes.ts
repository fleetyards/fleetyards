import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "home",
    redirect: {
      name: "api-v1",
    },
  },
  {
    path: "/api",
    name: "api",
    redirect: {
      name: "api-v1",
    },
  },
  {
    path: "/api/v1/",
    name: "api-v1",
    component: () => import("@/docs/pages/api/v1.vue"),
    props: {
      version: "v1",
    },
    meta: {
      title: "apiV1",
    },
  },
  {
    path: "/embed/",
    name: "embed",
    component: () => import("@/docs/pages/embed.vue"),
    meta: {
      title: "embed",
    },
  },
];
