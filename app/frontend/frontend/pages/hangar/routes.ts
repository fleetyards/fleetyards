import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "hangar",
    component: () => import("@/frontend/pages/hangar/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.index",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "wishlist/",
    name: "hangar-wishlist",
    component: () => import("@/frontend/pages/hangar/wishlist.vue"),
    meta: {
      needsAuthentication: true,
      quickSearch: "searchCont",
      title: "hangar.wishlist",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "preview/",
    name: "hangar-preview",
    component: () => import("@/frontend/pages/hangar/preview.vue"),
    meta: {
      title: "hangar.preview",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "fleetchart/",
    name: "hangar-fleetchart",
    redirect: {
      name: "hangar",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "stats/",
    name: "hangar-stats",
    component: () => import("@/frontend/pages/hangar/stats.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.stats",
      backgroundImage: "bg-5",
    },
  },
  {
    path: ":username/",
    name: "hangar-public",
    component: () => import("@/frontend/pages/hangar/[username].vue"),
    meta: {
      backgroundImage: "bg-5",
    },
  },
  {
    path: ":username/fleetchart/",
    name: "hangar-public-fleetchart",
    redirect: {
      name: "hangar-public",
      query: { fleetchart: "true" },
    },
  },
  {
    path: ":username/wishlist/",
    name: "wishlist-public",
    component: () => import("@/frontend/pages/hangar/[username]/wishlist.vue"),
    meta: {
      backgroundImage: "bg-5",
    },
  },
];
