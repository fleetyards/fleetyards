import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-tours",
    component: () => import("@/frontend/pages/fleets/[slug]/tours/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.tours.index",
      needsAuthentication: true,
      feature: [FeatureFlagName.TOUR_PAYOUTS, FeatureFlagName.FLEET_TOURS],
      featureScope: "fleet",
      customTitle: true,
    },
  },
  {
    path: "new/",
    name: "fleet-tour-new",
    component: () => import("@/frontend/pages/fleets/[slug]/tours/add.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.tours.create",
      needsAuthentication: true,
      feature: [FeatureFlagName.TOUR_PAYOUTS, FeatureFlagName.FLEET_TOURS],
      featureScope: "fleet",
      access: ["fleet:payouts:create", "fleet:payouts:manage", "fleet:manage"],
      customTitle: true,
    },
  },
  {
    path: ":tour/",
    name: "fleet-tour",
    component: () => import("@/frontend/pages/fleets/[slug]/tours/[tour].vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.tours.show",
      needsAuthentication: true,
      feature: [FeatureFlagName.TOUR_PAYOUTS, FeatureFlagName.FLEET_TOURS],
      featureScope: "fleet",
      customTitle: true,
    },
  },
];
