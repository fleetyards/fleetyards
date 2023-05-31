import publicUserCollection from "@/frontend/api/collections/PublicUser";
import { Route, NavigationGuardNext } from "vue-router";

export const publicHangarRouteGuard = async function publicHangarRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) {
  const response = await publicUserCollection.findByUsername(
    to.params.username
  );

  if (!response.data) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default publicHangarRouteGuard;
