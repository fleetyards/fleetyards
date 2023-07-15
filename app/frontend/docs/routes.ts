import type { RouteConfig } from "vue-router";

export const routes: RouteConfig[] = [
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
    component: () => import("@/docs/pages/Api.vue"),
    props: {
      version: "v1",
    },
    meta: {
      title: "api.v1",
    },
  },
  {
    path: "/embed/",
    name: "embed",
    component: () => import("@/docs/pages/Embed.vue"),
    meta: {
      title: "embed",
    },
  },
];
