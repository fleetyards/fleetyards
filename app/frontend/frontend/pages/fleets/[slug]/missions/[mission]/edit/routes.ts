import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-mission-edit",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission]/edit/index.vue"),
    meta: {
      title: "fleets.missions.edit.basic",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "fleet-missions",
      access: [
        "fleet:missions:update",
        "fleet:missions:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
  {
    path: "description/",
    name: "fleet-mission-edit-description",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission]/edit/description.vue"),
    meta: {
      title: "fleets.missions.edit.description",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "fleet-missions",
      access: [
        "fleet:missions:update",
        "fleet:missions:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
  {
    path: "teams/",
    name: "fleet-mission-edit-teams",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission]/edit/teams.vue"),
    meta: {
      title: "fleets.missions.edit.teams",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "fleet-missions",
      access: [
        "fleet:missions:update",
        "fleet:missions:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
];
