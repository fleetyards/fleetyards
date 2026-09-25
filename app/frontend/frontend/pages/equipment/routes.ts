import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "equipment",
    component: () => import("@/frontend/pages/equipment/index.vue"),
    meta: {
      title: "equipment.index",
      nav: "main",
    },
  },
  {
    // One view, so a page rather than a shell with tabs: there is no change log
    // for equipment the way there is for components.
    path: ":slug/",
    name: "equipment-item",
    component: () => import("@/frontend/pages/equipment/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
