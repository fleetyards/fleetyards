import { me as fetchMe } from "@/services/fyApi";

export const enabledRouteGuard = async function fleetRouteGuard() {
  const user = await fetchMe();

  if (!user.twoFactorRequired) {
    return { name: "settings-security-status" };
  }
};

export const disabledRouteGuard = async function publicFleetRouteGuard() {
  const user = await fetchMe();

  if (user.twoFactorRequired) {
    return { name: "settings-security-status" };
  }
};
