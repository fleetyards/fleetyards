import stationsCollection from "@/frontend/api/collections/Stations";

import { RouteLocation, NavigationGuardNext } from "vue-router";

export const stationRouteGuard = async function stationRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext
) {
  const station = await stationsCollection.findBySlug(String(to.params.slug));

  if (!station) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default stationRouteGuard;
