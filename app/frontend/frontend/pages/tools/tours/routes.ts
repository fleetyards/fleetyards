import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "tours",
    component: () => import("@/frontend/pages/tools/tours/index.vue"),
    meta: {
      title: "tools.tours.index",
      needsAuthentication: true,
      backgroundImage: "bg-7",
    },
  },
  {
    path: "add/",
    name: "tour-add",
    component: () => import("@/frontend/pages/tools/tours/add.vue"),
    meta: {
      title: "tools.tours.add",
      needsAuthentication: true,
      backgroundImage: "bg-7",
    },
  },
  {
    path: "join/:token/",
    name: "tour-join",
    component: () => import("@/frontend/pages/tools/tours/join.vue"),
    meta: {
      title: "tools.tours.join",
      needsAuthentication: true,
      backgroundImage: "bg-7",
    },
  },
  {
    path: ":slug/",
    name: "tour",
    component: () => import("@/frontend/pages/tools/tours/[slug].vue"),
    meta: {
      title: "tools.tours.show",
      needsAuthentication: true,
      backgroundImage: "bg-7",
      customTitle: true,
    },
  },
];
