import type { RouteMeta, RouteRecordRaw } from "vue-router";

const meta: RouteMeta = {
  needsAuthentication: true,
  nav: "editTabs",
  activeRoute: "fleet-events",
  access: ["fleet:events:update", "fleet:events:manage", "fleet:manage"],
  customTitle: true,
};

/*
 * Grouped by what each field is about. "Basic info" had collected the title,
 * the dates, the place, the signup rules and the whole recurrence block at
 * once, while a tab called "Description" owned the cover art -- so the longest
 * tab was the one with no subject and the art was filed under prose.
 */
export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-event-edit",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/index.vue"),
    meta: { ...meta, title: "fleets.events.edit.details" },
  },
  {
    path: "schedule/",
    name: "fleet-event-edit-schedule",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/schedule.vue"),
    meta: { ...meta, title: "fleets.events.edit.schedule" },
  },
  {
    path: "signup/",
    name: "fleet-event-edit-signup",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/signup.vue"),
    meta: { ...meta, title: "fleets.events.edit.signup" },
  },
  {
    path: "teams/",
    name: "fleet-event-edit-teams",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/events/[event]/edit/teams.vue"),
    meta: { ...meta, title: "fleets.events.edit.teams" },
  },
  {
    // Was a tab of its own; its fields moved into Details. The path stays so
    // links people already have keep resolving.
    path: "description/",
    redirect: { name: "fleet-event-edit" },
  },
];
