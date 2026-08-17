import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-members-index",
    component: () => import("@/frontend/pages/fleets/[slug]/members/index.vue"),
    meta: {
      title: "fleets.members.index",
      needsAuthentication: true,
      customTitle: true,
    },
  },
  {
    path: "worldmap/",
    name: "fleet-members-worldmap",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/members/worldmap.vue"),
    meta: {
      title: "fleets.members.worldmap",
      needsAuthentication: true,
      customTitle: true,
      feature: FeatureFlagName.FLEET_WORLDMAP,
    },
  },
  {
    path: "starmap/",
    name: "fleet-members-starmap",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/members/starmap.vue"),
    meta: {
      title: "fleets.members.starmap",
      needsAuthentication: true,
      customTitle: true,
      feature: FeatureFlagName.FLEET_STARMAP,
    },
  },
  {
    path: "invites/",
    name: "fleet-members-invites",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/members/invites.vue"),
    meta: {
      title: "fleets.members.invites",
      needsAuthentication: true,
      access: [
        "fleet:memberships:read",
        "fleet:memberships:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
];
