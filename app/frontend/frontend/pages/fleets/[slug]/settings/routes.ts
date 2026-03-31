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
      customTitle: true,
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
      customTitle: true,
    },
  },
  {
    path: "roles/",
    name: "fleet-settings-roles",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/roles.vue"),
    meta: {
      title: "fleets.settings.roles",
      needsAuthentication: true,
      access: ["fleet:roles:read", "fleet:roles:manage", "fleet:manage"],
      customTitle: true,
    },
  },
];
