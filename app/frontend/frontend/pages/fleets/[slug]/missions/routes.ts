import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-missions",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.missions.index",
      needsAuthentication: true,
      access: ["fleet:missions:read", "fleet:missions:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: ":mission/",
    name: "fleet-mission",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission].vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.missions.edit",
      needsAuthentication: true,
      access: ["fleet:missions:read", "fleet:missions:manage", "fleet:manage"],
      customTitle: true,
    },
  },
];
