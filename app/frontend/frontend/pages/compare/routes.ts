import type { RouteRecordRaw } from "vue-router";

// One page with a tab per catalogue (`nav: "pageTabs"`), so the tab strip stays
// mounted when the reader switches between them.
export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "compare",
    component: () => import("@/frontend/pages/compare/ships.vue"),
    meta: {
      title: "compare.ships",
      nav: "pageTabs",
    },
  },
  {
    path: "components/",
    name: "compare-components",
    component: () => import("@/frontend/pages/compare/components.vue"),
    meta: {
      title: "compare.components",
      nav: "pageTabs",
    },
  },
  {
    path: "equipment/",
    name: "compare-equipment",
    component: () => import("@/frontend/pages/compare/equipment.vue"),
    meta: {
      title: "compare.equipment",
      nav: "pageTabs",
    },
  },
];
