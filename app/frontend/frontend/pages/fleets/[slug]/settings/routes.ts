import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "fleet/",
    name: "fleet-settings-fleet",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/fleet.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "membership/",
    name: "fleet-settings-membership",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/membership.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
];

export default routes;
