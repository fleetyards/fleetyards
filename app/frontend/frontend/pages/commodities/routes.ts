import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "commodities",
    component: () => import("@/frontend/pages/commodities/index.vue"),
    meta: {
      title: "commodities.index",
      nav: "main",
    },
  },
  {
    // A page rather than a shell with tabs: the commodity has one view, and the
    // price history is a panel on it rather than a sibling route. Components
    // needed the shell because its change log is a second query nobody opening
    // the overview should pay for.
    path: ":slug/",
    name: "commodity",
    component: () => import("@/frontend/pages/commodities/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
