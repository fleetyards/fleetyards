/*
 * The admin area's own gallery. It cannot live in the frontend's: these
 * components import the admin API client and the admin stores, and the two apps
 * are separate entrypoints.
 *
 * Explicit imports rather than a glob, for the same reasons as the frontend's:
 * stable route names for the e2e specs, and a gated branch that stays one array
 * a live build can drop whole.
 */
export const routes = [
  {
    path: "notifications/",
    name: "admin-visual-tests-notifications",
    component: () => import("@/admin/pages/visual-tests/notifications.vue"),
    meta: {
      title: "admin.visualTests.notifications",
      /*
       * Behind the login like every other admin route. The gallery is stripped
       * from a live build, but on stage the admin area is real, and an
       * unauthenticated route there would be a hole punched for a demo page.
       */
      needsAuthentication: true,
    },
  },
];
