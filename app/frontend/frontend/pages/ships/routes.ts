import type { RouteRecordRaw } from "vue-router";
import { routes as shipRoutes } from "@/frontend/pages/ships/[slug]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "models",
    component: () => import("@/frontend/pages/ships/index.vue"),
    meta: {
      title: "models.index",
      quickSearch: "searchCont",
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
    name: "models-fleetchart",
    redirect: {
      name: "models",
      query: { fleetchart: "true" },
    },
  },
];
