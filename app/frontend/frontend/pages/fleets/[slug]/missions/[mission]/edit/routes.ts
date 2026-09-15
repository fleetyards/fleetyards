import type { RouteMeta, RouteRecordRaw } from "vue-router";

const meta: RouteMeta = {
  needsAuthentication: true,
  nav: "editTabs",
  activeRoute: "fleet-missions",
  access: ["fleet:missions:update", "fleet:missions:manage", "fleet:manage"],
  customTitle: true,
};

/*
 * A mission has no schedule and no signup rules -- it is the template an event
 * is spawned from -- so it splits in two where an event splits in four. What it
 * is, and who flies it.
 */
export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-mission-edit",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission]/edit/index.vue"),
    meta: { ...meta, title: "fleets.missions.edit.details" },
  },
  {
    path: "teams/",
    name: "fleet-mission-edit-teams",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission]/edit/teams.vue"),
    meta: { ...meta, title: "fleets.missions.edit.teams" },
  },
  {
    // Was a tab of its own; its fields moved into Details. The path stays so
    // links people already have keep resolving.
    path: "description/",
    redirect: { name: "fleet-mission-edit" },
  },
];
