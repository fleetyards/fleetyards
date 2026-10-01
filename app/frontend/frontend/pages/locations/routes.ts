import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "locations",
    component: () => import("@/frontend/pages/locations/index.vue"),
    meta: {
      title: "locations.index",
      nav: "main",
    },
  },
  {
    path: ":slug/",
    name: "location",
    component: () => import("@/frontend/pages/locations/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
