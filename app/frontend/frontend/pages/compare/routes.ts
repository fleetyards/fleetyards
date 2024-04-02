import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "ships/",
    name: "compare-ships",
    component: () => import("@/frontend/pages/compare/ships.vue"),
    meta: {
      title: "compare.ships",
    },
  },
];
