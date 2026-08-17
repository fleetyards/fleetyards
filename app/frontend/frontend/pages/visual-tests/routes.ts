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
    path: "typography/",
    name: "visual-tests-typography",
    component: () => import("@/frontend/pages/visual-tests/typography.vue"),
    meta: {
      title: "visualTests.typography",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "forms/",
    name: "visual-tests-forms",
    component: () => import("@/frontend/pages/visual-tests/forms.vue"),
    meta: {
      title: "visualTests.forms",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "lists/",
    name: "visual-tests-lists",
    component: () => import("@/frontend/pages/visual-tests/lists.vue"),
    meta: {
      title: "visualTests.lists",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "metrics/",
    name: "visual-tests-metrics",
    component: () => import("@/frontend/pages/visual-tests/metrics.vue"),
    meta: {
      title: "visualTests.metrics",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "states/",
    name: "visual-tests-states",
    component: () => import("@/frontend/pages/visual-tests/states.vue"),
    meta: {
      title: "visualTests.states",
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
    path: "sync-modal/",
    name: "visual-tests-sync-modal",
    component: () => import("@/frontend/pages/visual-tests/sync-modal.vue"),
    meta: {
      title: "visualTests.syncModal",
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
  {
    path: "chips/",
    name: "visual-tests-chips",
    component: () => import("@/frontend/pages/visual-tests/chips.vue"),
    meta: {
      title: "visualTests.chips",
      backgroundImage: "bg-7",
    },
  },
];
