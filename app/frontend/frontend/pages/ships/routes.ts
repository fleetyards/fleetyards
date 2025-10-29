import type { RouteRecordRaw } from "vue-router";
import { routes as shipRoutes } from "@/frontend/pages/ships/[slug]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "ships",
    component: () => import("@/frontend/pages/ships/index.vue"),
    meta: {
      title: "ships.index",
    },
  },
  {
    path: ":slug/",
    component: () => import("@/frontend/pages/ships/[slug].vue"),
    children: shipRoutes,
    redirect: { name: shipRoutes[0].name },
  },
  {
    path: "fleetchart/",
    name: "ships-fleetchart",
    redirect: {
      name: "ships",
      query: { fleetchart: "true" },
    },
  },
];
