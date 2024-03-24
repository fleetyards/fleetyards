import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "roadmap",
    component: () => import("@/frontend/pages/roadmap/index.vue"),
    meta: {
      title: "roadmap.index",
    },
  },
  {
    path: "changes/",
    name: "roadmap-changes",
    component: () => import("@/frontend/pages/roadmap/changes.vue"),
    meta: {
      title: "roadmap.changes",
    },
  },
  {
    path: "ships/",
    name: "roadmap-ships",
    component: () => import("@/frontend/pages/roadmap/ships.vue"),
    meta: {
      title: "roadmap.ships",
    },
  },
];

export default routes;
