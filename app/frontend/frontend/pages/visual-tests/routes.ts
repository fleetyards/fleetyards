export const routes = [
  {
    path: "",
    name: "visual-tests",
    component: () => import("@/frontend/pages/visual-tests/index.vue"),
    meta: {
      title: "visualTests.overview",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "panels/",
    name: "visual-tests-panels",
    component: () => import("@/frontend/pages/visual-tests/panels-page.vue"),
    meta: {
      title: "visualTests.panels",
      backgroundImage: "bg-7",
    },
  },
];

export default routes;
