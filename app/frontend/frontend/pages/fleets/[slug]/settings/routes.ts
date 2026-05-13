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
  {
    path: "notifications/",
    name: "fleet-settings-notifications",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/notifications.vue"),
    meta: {
      title: "fleets.settings.notifications",
      needsAuthentication: true,
      access: ["fleet:notifications:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: "discord/",
    name: "fleet-settings-discord",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/discord.vue"),
    meta: {
      title: "fleets.settings.discord",
      needsAuthentication: true,
      access: ["fleet:notifications:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: "calendar/",
    name: "fleet-settings-calendar",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/settings/calendar.vue"),
    meta: {
      title: "fleets.settings.calendar",
      needsAuthentication: true,
      access: ["fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
];
