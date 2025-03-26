import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "membership/",
    name: "fleet-settings-membership",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/membership.vue"),
    meta: {
      title: "fleets.settings.membership",
      needsAuthentication: true,
    },
  },
  {
    path: "fleet/",
    name: "fleet-settings-fleet",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/fleet.vue"),
    meta: {
      title: "fleets.settings.fleet",
      needsAuthentication: true,
      access: ["fleet:manage"],
    },
  },
];

export default routes;
