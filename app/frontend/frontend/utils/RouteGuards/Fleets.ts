import fleetsCollection from "@/frontend/api/collections/Fleets";
import { Route, NavigationGuardNext } from "vue-router";

export const fleetRouteGuard = async function fleetRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) {
  const response = await fleetsCollection.findBySlug(to.params.slug);
  const fleet = response.data;

  if (!fleet || !fleet.myFleet) {
    next({ name: "404" });
  } else {
    next();
  }
};

export const publicFleetRouteGuard = async function publicFleetRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) {
  const response = await fleetsCollection.findBySlug(to.params.slug);

  if (!response.data) {
    next({ name: "404" });
  } else {
    next();
  }
};

export const publicFleetShipsRouteGuard =
  async function publicFleetShipsRouteGuard(
    to: Route,
    _from: Route,
    next: NavigationGuardNext
  ) {
    const response = await fleetsCollection.findBySlug(to.params.slug);
    const fleet = response.data;

    if (!fleet || (!fleet.publicFleet && !fleet.myFleet)) {
      next({ name: "404" });
    } else {
      next();
    }
  };
