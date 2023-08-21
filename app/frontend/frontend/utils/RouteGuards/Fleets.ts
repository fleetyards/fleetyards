import fleetsCollection from "@/frontend/api/collections/Fleets";
import { RouteLocation, NavigationGuardNext } from "vue-router";

export const fleetRouteGuard = async function fleetRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext
) {
  const fleet = await fleetsCollection.findBySlug(String(to.params.slug));

  if (!fleet || !fleet.myFleet) {
    next({ name: "404" });
  } else {
    next();
  }
};

export const publicFleetRouteGuard = async function publicFleetRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext
) {
  const fleet = await fleetsCollection.findBySlug(String(to.params.slug));

  if (!fleet) {
    next({ name: "404" });
  } else {
    next();
  }
};

export const publicFleetShipsRouteGuard =
  async function publicFleetShipsRouteGuard(
    to: RouteLocation,
    _from: RouteLocation,
    next: NavigationGuardNext
  ) {
    const fleet = await fleetsCollection.findBySlug(String(to.params.slug));

    if (!fleet || (!fleet.publicFleet && !fleet.myFleet)) {
      next({ name: "404" });
    } else {
      next();
    }
  };
