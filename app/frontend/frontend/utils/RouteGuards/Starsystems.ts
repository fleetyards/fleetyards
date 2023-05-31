import starsystemsCollection from "@/frontend/api/collections/Starsystems";
import { Route, NavigationGuardNext } from "vue-router";

export const starsystemRouteGuard = async function modelRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) {
  const response = await starsystemsCollection.findBySlug(to.params.slug);

  if (!response.data) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default starsystemRouteGuard;
