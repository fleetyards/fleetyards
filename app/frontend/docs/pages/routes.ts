import type { RouteRecordRaw } from "vue-router";
import { routes as apiV1Routes } from "./api/v1/routes";
import { routes as authApiV1Routes } from "./api/auth-v1/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "home",
    redirect: {
      name: "api-v1-schema",
    },
    meta: {
      nav: "hidden",
    },
  },
  {
    path: "/api/",
    name: "api",
    redirect: {
      name: "api-v1-schema",
    },
    meta: {
      nav: "hidden",
    },
  },
  {
    path: "/api/v1/",
    name: "api-v1",
    component: () => import("@/docs/pages/api/v1.vue"),
    redirect: {
      name: "api-v1-schema",
    },
    meta: {
      title: "apiV1",
      icon: "fa-duotone fa-brackets-curly",
      mobileNav: 0,
    },
    children: apiV1Routes,
  },
  {
    path: "/api/auth/v1/",
    name: "api-auth-v1",
    component: () => import("@/docs/pages/api/auth-v1.vue"),
    redirect: {
      name: "api-auth-v1-schema",
    },
    meta: {
      title: "authApiV1",
      icon: "fa-duotone fa-shield-check",
      mobileNav: 1,
    },
    children: authApiV1Routes,
  },
  {
    path: "/embed/",
    name: "embed",
    component: () => import("@/docs/pages/embed.vue"),
    meta: {
      title: "embed",
      icon: "fa-duotone fa-arrow-up-from-square",
      mobileNav: 2,
    },
  },
];
