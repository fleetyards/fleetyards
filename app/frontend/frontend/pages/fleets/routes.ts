import type { RouteRecordRaw } from "vue-router";
import { routes as fleetRoutes } from "@/frontend/pages/fleets/[slug]/routes";
import { FeatureFlagName } from "@/services/fyApi";
import { featuresQueryOptions } from "@/frontend/composables/useFeatures";
import { ensureQueryData } from "@/frontend/utils/RouteGuards/queryData";

// The directory, once it is rolled out, is what /fleets/ is for; until then
// it is where a fleet gets made. A redirect cannot wait for the flags, so the
// index decides before it is entered.
const fleetsIndexGuard = async () => {
  try {
    const features = await ensureQueryData(featuresQueryOptions());

    if (features?.includes(FeatureFlagName.FLEET_DIRECTORY)) {
      return { name: "fleet-directory" };
    }
  } catch {
    // Fall through to the page /fleets/ led to before the directory.
  }

  return { name: "fleet-add" };
};

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleets",
    component: () => import("@/frontend/pages/fleets/directory.vue"),
    beforeEnter: fleetsIndexGuard,
  },
  {
    path: "directory/",
    name: "fleet-directory",
    component: () => import("@/frontend/pages/fleets/directory.vue"),
    meta: {
      title: "fleets.directory",
      feature: FeatureFlagName.FLEET_DIRECTORY,
    },
  },
  {
    path: "add/",
    name: "fleet-add",
    component: () => import("@/frontend/pages/fleets/add.vue"),
    meta: {
      needsAuthentication: true,
      title: "fleets.add",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "preview/",
    name: "fleet-preview",
    component: () => import("@/frontend/pages/fleets/preview.vue"),
    meta: {
      title: "fleets.preview",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "invites/",
    name: "fleet-invites",
    component: () => import("@/frontend/pages/fleets/invites.vue"),
    meta: {
      needsAuthentication: true,
      title: "fleets.invites",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "invites/:token/",
    name: "fleet-invite",
    component: () => import("@/frontend/pages/fleets/invite.vue"),
    meta: {
      needsAuthentication: true,
      backgroundImage: "bg-8",
    },
  },
  {
    path: ":slug/",
    component: () => import("@/frontend/pages/fleets/[slug].vue"),
    children: fleetRoutes,
    redirect: { name: fleetRoutes[0].name },
  },
];
