export const routes = [
  {
    path: "",
    name: "tools",
    component: () => import("@/frontend/pages/tools/index.vue"),
    meta: {
      title: "tools.index",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "travel-times/",
    name: "travel-times",
    component: () => import("@/frontend/pages/tools/travel-times.vue"),
    meta: {
      title: "tools.travelTimes",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "cargo-grids/",
    name: "cargo-grids",
    component: () => import("@/frontend/pages/tools/cargo-grids.vue"),
    meta: {
      title: "tools.cargoGrids",
      backgroundImage: "bg-8",
    },
  },
];
