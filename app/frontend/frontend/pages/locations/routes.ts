import { FeatureFlagName } from "@/services/fyApi";
import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "locations",
    component: () => import("@/frontend/pages/locations/index.vue"),
    meta: {
      title: "locations.index",
      nav: "main",
    },
  },
  {
    path: "places/",
    name: "locations-places",
    component: () => import("@/frontend/pages/locations/places.vue"),
    meta: {
      mobileBack: true,
      title: "locations.places",
    },
  },
  // Every system's places at the positions the game gives them, in 3D.
  // Before the place route, which would take "starmap" for a slug.
  {
    path: "starmap/",
    name: "starmap",
    component: () => import("@/frontend/pages/starmap.vue"),
    meta: {
      title: "starmap",
      feature: FeatureFlagName.STARMAP,
      fullscreen: true,
    },
  },
  {
    path: ":slug/",
    name: "location",
    component: () => import("@/frontend/pages/locations/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
