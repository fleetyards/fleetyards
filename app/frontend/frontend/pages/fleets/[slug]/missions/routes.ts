import type { RouteRecordRaw } from "vue-router";
import { routes as missionEditRoutes } from "@/frontend/pages/fleets/[slug]/missions/[mission]/edit/routes";

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
    path: "new/",
    name: "fleet-mission-new",
    component: () => import("@/frontend/pages/fleets/[slug]/missions/new.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.missions.create",
      needsAuthentication: true,
      access: [
        "fleet:missions:create",
        "fleet:missions:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
  {
    path: ":mission/edit/",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/missions/[mission]/edit.vue"),
    children: missionEditRoutes,
    redirect: { name: missionEditRoutes[0].name as string },
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.missions.edit",
      needsAuthentication: true,
      access: [
        "fleet:missions:update",
        "fleet:missions:manage",
        "fleet:manage",
      ],
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
      title: "fleets.missions.show",
      needsAuthentication: true,
      access: ["fleet:missions:read", "fleet:missions:manage", "fleet:manage"],
      customTitle: true,
    },
  },
];
