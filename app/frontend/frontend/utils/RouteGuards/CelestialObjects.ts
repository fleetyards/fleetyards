import celestialObjectsCollection from "@/frontend/api/collections/CelestialObjects";

import { Route, NavigationGuardNext } from "vue-router";

export const celestialObjectRouteGuard = async (
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) => {
  const response = await celestialObjectsCollection.findBySlug(to.params.slug);

  if (!response.data) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default celestialObjectRouteGuard;
