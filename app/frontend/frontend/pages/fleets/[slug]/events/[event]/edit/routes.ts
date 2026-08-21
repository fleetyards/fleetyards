import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-event-edit",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/index.vue"),
    meta: {
      title: "fleets.events.edit.basic",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "fleet-events",
      access: ["fleet:events:update", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: "description/",
    name: "fleet-event-edit-description",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/description.vue"),
    meta: {
      title: "fleets.events.edit.description",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "fleet-events",
      access: ["fleet:events:update", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: "teams/",
    name: "fleet-event-edit-teams",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/teams.vue"),
    meta: {
      title: "fleets.events.edit.teams",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "fleet-events",
      access: ["fleet:events:update", "fleet:events:manage", "fleet:manage"],
      customTitle: true,
    },
  },
];
