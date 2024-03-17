import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "fleet/",
    name: "fleet-settings-fleet",
    component: () =>
      import("@/frontend/pages/Fleets/Show/Settings/Fleet/index.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "membership/",
    name: "fleet-settings-membership",
    component: () =>
      import("@/frontend/pages/Fleets/Show/Settings/Membership/index.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
];

export default routes;
