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
      feature: "tools_travel_times",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "cargo-grids/",
    name: "cargo-grids",
    component: () => import("@/frontend/pages/tools/cargo-grids.vue"),
    meta: {
      title: "tools.cargoGrids",
      feature: "tools_cargo_grids",
      backgroundImage: "bg-8",
    },
  },
];
