import publicUserCollection from "@/frontend/api/collections/PublicUser";

import { RouteLocation, NavigationGuardNext } from "vue-router";

export const publicHangarRouteGuard = async function publicHangarRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext,
) {
  const user = await publicUserCollection.findByUsername(
    String(to.params.username),
  );

  if (!user) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default publicHangarRouteGuard;
