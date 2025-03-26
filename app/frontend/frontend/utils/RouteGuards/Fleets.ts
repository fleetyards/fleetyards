import { RouteLocation, NavigationGuardNext } from "vue-router";
import {
  fleet as fetchFleet,
  fleetMembership as fetchFleetMembership,
} from "@/services/fyApi";

export const fleetRouteGuard = async function fleetRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext,
) {
  await fetchFleetMembership(String(to.params.slug))
    .then((_membership) => {
      next();
    })
    .catch((_error) => {
      next({ name: "404" });
    });
};

export const publicFleetRouteGuard = async function publicFleetRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext,
) {
  const fleet = await fetchFleet(String(to.params.slug));

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
    next: NavigationGuardNext,
  ) {
    const fleet = await fetchFleet(String(to.params.slug));

    if (!fleet || (!fleet.publicFleet && !fleet.myFleet)) {
      next({ name: "404" });
    } else {
      next();
    }
  };
