import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "changes/",
    name: "roadmap-changes",
    component: () => import("@/frontend/pages/Roadmap/Changes/index.vue"),
    meta: {
      title: "roadmap.changes",
    },
  },
  {
    path: "ships/",
    name: "roadmap-ships",
    component: () => import("@/frontend/pages/Roadmap/Ships/index.vue"),
    meta: {
      title: "roadmap.ships",
    },
  },
];

export default routes;
