export const routes = [
  {
    path: "panels/",
    name: "visual-tests-panels",
    component: () => import("@/frontend/pages/visual-tests/panels.vue"),
    meta: {
      title: "visualTests.panels",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "buttons/",
    name: "visual-tests-buttons",
    component: () => import("@/frontend/pages/visual-tests/buttons.vue"),
    meta: {
      title: "visualTests.buttons",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "tables/",
    name: "visual-tests-tables",
    component: () => import("@/frontend/pages/visual-tests/tables.vue"),
    meta: {
      title: "visualTests.tables",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "notifications/",
    name: "visual-tests-notifications",
    component: () => import("@/frontend/pages/visual-tests/notifications.vue"),
    meta: {
      title: "visualTests.notifications",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "support-hint/",
    name: "visual-tests-support-hint",
    component: () => import("@/frontend/pages/visual-tests/support-hint.vue"),
    meta: {
      title: "visualTests.supportHint",
      backgroundImage: "bg-7",
    },
  },
];
