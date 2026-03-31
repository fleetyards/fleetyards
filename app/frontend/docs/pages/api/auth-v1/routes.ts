import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "api-auth-v1-schema",
    component: () => import("@/docs/pages/api/auth-v1/index.vue"),
    meta: {
      title: "authApiV1Schema",
      nav: "hidden",
    },
  },
  {
    path: "openid/",
    name: "api-auth-v1-openid",
    component: () => import("@/docs/pages/api/auth-v1/openid.vue"),
    meta: {
      title: "authApiV1OpenId",
      nav: "hidden",
    },
  },
];
