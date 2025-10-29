import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "hangar-public",
    component: () => import("@/frontend/pages/hangar/[username]/index.vue"),
    meta: {
      backgroundImage: "bg-5",
    },
  },
  {
    path: "fleetchart/",
    name: "hangar-public-fleetchart",
    redirect: {
      name: "hangar-public",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "wishlist/",
    name: "wishlist-public",
    component: () => import("@/frontend/pages/hangar/[username]/wishlist.vue"),
    meta: {
      backgroundImage: "bg-5",
    },
  },
];
