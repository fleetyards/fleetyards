import type { RouteRecordRaw } from "vue-router";

// A tab per catalogue. `nav: "pageTabs"` gives the three one page key, so a
// switch between them is not a page change and the app's page transition does
// not play across it.
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
