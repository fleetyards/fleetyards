import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";
import { squadronFormRoutes } from "@/frontend/pages/fleets/[slug]/squadrons/form/routes";

const SQUADRON_READ_ACCESS = [
  "fleet:squadrons:read",
  "fleet:squadrons:manage",
  "fleet:manage",
];

const SQUADRON_CREATE_ACCESS = [
  "fleet:squadrons:create",
  "fleet:squadrons:manage",
  "fleet:manage",
];

const SQUADRON_UPDATE_ACCESS = [
  "fleet:squadrons:update",
  "fleet:squadrons:manage",
  "fleet:manage",
];

const SQUADRON_CREATE_ROUTES = squadronFormRoutes(
  "create",
  SQUADRON_CREATE_ACCESS,
);

const SQUADRON_EDIT_ROUTES = squadronFormRoutes("edit", SQUADRON_UPDATE_ACCESS);

export const squadronDetailRoutes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-squadron",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron]/overview.vue"),
    meta: {
      title: "fleets.squadrons.overview",
      needsAuthentication: true,
      access: SQUADRON_READ_ACCESS,
      customTitle: true,
    },
  },
  {
    path: "members/",
    name: "fleet-squadron-members",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron]/members.vue"),
    meta: {
      title: "fleets.squadrons.members",
      needsAuthentication: true,
      access: SQUADRON_READ_ACCESS,
      customTitle: true,
    },
  },
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
      fleetSetting: "squadronsEnabled",
      customTitle: true,
    },
  },
  {
    path: "new/",
    component: () => import("@/frontend/pages/fleets/[slug]/squadrons/new.vue"),
    children: SQUADRON_CREATE_ROUTES,
    redirect: { name: SQUADRON_CREATE_ROUTES[0].name as string },
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.create",
      needsAuthentication: true,
      access: SQUADRON_CREATE_ACCESS,
      feature: FeatureFlagName.FLEET_SQUADRONS,
      featureScope: "fleet",
      fleetSetting: "squadronsEnabled",
      customTitle: true,
    },
  },
  {
    path: ":squadron/edit/",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron]/edit.vue"),
    children: SQUADRON_EDIT_ROUTES,
    redirect: { name: SQUADRON_EDIT_ROUTES[0].name as string },
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.edit",
      needsAuthentication: true,
      access: SQUADRON_UPDATE_ACCESS,
      feature: FeatureFlagName.FLEET_SQUADRONS,
      featureScope: "fleet",
      fleetSetting: "squadronsEnabled",
      customTitle: true,
    },
  },
  {
    path: ":squadron/",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron].vue"),
    children: squadronDetailRoutes,
    redirect: { name: "fleet-squadron" },
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.squadrons.index",
      needsAuthentication: true,
      access: SQUADRON_READ_ACCESS,
      feature: FeatureFlagName.FLEET_SQUADRONS,
      featureScope: "fleet",
      fleetSetting: "squadronsEnabled",
      customTitle: true,
    },
  },
];
