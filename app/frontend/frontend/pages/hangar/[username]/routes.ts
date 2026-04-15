import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "hangar-public",
    component: () => import("@/frontend/pages/hangar/[username]/index.vue"),
    meta: {
      title: "hangar.public",
      backgroundImage: "bg-5",
      customTitle: true,
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
    path: "stats/",
    name: "hangar-public-stats",
    component: () => import("@/frontend/pages/hangar/[username]/stats.vue"),
    meta: {
      title: "hangar.publicStats",
      backgroundImage: "bg-5",
      customTitle: true,
    },
  },
  {
    path: "wishlist/",
    name: "wishlist-public",
    component: () => import("@/frontend/pages/hangar/[username]/wishlist.vue"),
    meta: {
      title: "hangar.publicWishlist",
      backgroundImage: "bg-5",
      customTitle: true,
    },
  },
];
