import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "missions",
    component: () => import("@/frontend/pages/missions/index.vue"),
    meta: {
      mobileBack: true,
      title: "missions.index",
      nav: "main",
    },
  },
  {
    path: ":slug/",
    name: "mission",
    component: () => import("@/frontend/pages/missions/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
