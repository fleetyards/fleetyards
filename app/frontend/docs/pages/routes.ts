import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "home",
    redirect: {
      name: "api-v1",
    },
    meta: {
      nav: "hidden",
    },
  },
  {
    path: "/api/",
    name: "api",
    redirect: {
      name: "api-v1",
    },
    meta: {
      nav: "hidden",
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
      icon: "fa-duotone fa-books",
      mobileNav: 0,
    },
  },
  {
    path: "/api/oauth/v1/",
    name: "api-oauth-v1",
    component: () => import("@/docs/pages/api/oauth-v1.vue"),
    meta: {
      title: "oauthApiV1",
      icon: "fa-duotone fa-key",
      mobileNav: 1,
    },
  },
  {
    path: "/embed/",
    name: "embed",
    component: () => import("@/docs/pages/embed.vue"),
    meta: {
      title: "embed",
      icon: "fa-duotone fa-arrow-up-from-square",
      mobileNav: 1,
    },
  },
];
