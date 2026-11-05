import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "factions",
    component: () => import("@/frontend/pages/factions/index.vue"),
    meta: {
      mobileBack: true,
      title: "factions.index",
      nav: "main",
    },
  },
  {
    path: ":slug/",
    name: "faction",
    component: () => import("@/frontend/pages/factions/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
