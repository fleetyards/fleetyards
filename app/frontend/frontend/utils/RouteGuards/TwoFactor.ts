import { me as fetchMe } from "@/services/fyApi";
import { RouteLocation, NavigationGuardNext } from "vue-router";

export const enabledRouteGuard = async function fleetRouteGuard(
  _to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext,
) {
  const user = await fetchMe();

  if (!user.twoFactorRequired) {
    next({ name: "settings-security-status" });
  } else {
    next();
  }
};

export const disabledRouteGuard = async function publicFleetRouteGuard(
  _to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext,
) {
  const user = await fetchMe();

  if (user.twoFactorRequired) {
    next({ name: "settings-security-status" });
  } else {
    next();
  }
};
