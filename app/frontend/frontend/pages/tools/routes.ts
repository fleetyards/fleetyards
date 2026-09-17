import type { RouteRecordRaw } from "vue-router";
import { routes as tourRoutes } from "@/frontend/pages/tools/tours/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "tools",
    component: () => import("@/frontend/pages/tools/index.vue"),
    meta: {
      title: "tools.index",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "travel-times/",
    name: "travel-times",
    component: () => import("@/frontend/pages/tools/travel-times.vue"),
    meta: {
      title: "tools.travelTimes",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "cargo-grids/",
    name: "cargo-grids",
    component: () => import("@/frontend/pages/tools/cargo-grids.vue"),
    meta: {
      title: "tools.cargoGrids",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "tours/",
    component: () => import("@/frontend/pages/tools/tours.vue"),
    children: tourRoutes,
    redirect: { name: tourRoutes[0].name as string },
  },
];
