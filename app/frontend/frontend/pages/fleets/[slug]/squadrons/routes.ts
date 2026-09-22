import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";
import { routes as squadronEditRoutes } from "@/frontend/pages/fleets/[slug]/squadrons/[squadron]/edit/routes";

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
    path: "new/",
    name: "fleet-squadron-new",
    component: () => import("@/frontend/pages/fleets/[slug]/squadrons/new.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.create",
      needsAuthentication: true,
      access: [
        "fleet:squadrons:create",
        "fleet:squadrons:manage",
        "fleet:manage",
      ],
      feature: FeatureFlagName.FLEET_SQUADRONS,
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: ":squadron/edit/",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron]/edit.vue"),
    children: squadronEditRoutes,
    redirect: { name: squadronEditRoutes[0].name as string },
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.edit",
      needsAuthentication: true,
      access: [
        "fleet:squadrons:update",
        "fleet:squadrons:manage",
        "fleet:manage",
      ],
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
