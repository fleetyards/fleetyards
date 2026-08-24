/*
 * A demo lives next to the component it documents - `Chip/visual.vue` beside
 * `Chip/index.vue` - so the two move, get reviewed and rot together. Only where
 * exactly one component owns the demo: a page covering a whole family (Btn with
 * BtnGroup and BtnDropdown) or several unrelated components stays here, and so
 * does one whose demo would drag `shared/` into a dependency on `frontend/`.
 *
 * Imports are explicit rather than an `import.meta.glob` sweep, so the route
 * names the e2e specs rely on stay stable and the gated branch in
 * `pages/routes.ts` remains one array a live build can drop whole.
 */
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
    path: "events/",
    name: "visual-tests-events",
    component: () => import("@/frontend/pages/visual-tests/events.vue"),
    meta: {
      title: "visualTests.events",
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
    component: () => import("@/shared/components/AppNotifications/visual.vue"),
    meta: {
      title: "visualTests.notifications",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "sync-modal/",
    name: "visual-tests-sync-modal",
    component: () =>
      import("@/frontend/components/Hangar/SyncBtn/Result/visual.vue"),
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
    path: "overlays/",
    name: "visual-tests-overlays",
    component: () => import("@/frontend/pages/visual-tests/overlays.vue"),
    meta: {
      title: "visualTests.overlays",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "media/",
    name: "visual-tests-media",
    component: () => import("@/frontend/pages/visual-tests/media.vue"),
    meta: {
      title: "visualTests.media",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "charts/",
    name: "visual-tests-charts",
    component: () => import("@/shared/components/Chart/visual.vue"),
    meta: {
      title: "visualTests.charts",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "chips/",
    name: "visual-tests-chips",
    component: () => import("@/shared/components/base/Chip/visual.vue"),
    meta: {
      title: "visualTests.chips",
      backgroundImage: "bg-7",
    },
  },
];
