import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

const SQUADRON_READ_ACCESS = [
  "fleet:squadrons:read",
  "fleet:squadrons:manage",
  "fleet:manage",
];

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-squadrons",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.index",
      needsAuthentication: true,
      access: SQUADRON_READ_ACCESS,
      feature: FeatureFlagName.FLEET_SQUADRONS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: ":squadron/",
    name: "fleet-squadron",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron].vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.index",
      needsAuthentication: true,
      access: SQUADRON_READ_ACCESS,
      feature: FeatureFlagName.FLEET_SQUADRONS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
];
