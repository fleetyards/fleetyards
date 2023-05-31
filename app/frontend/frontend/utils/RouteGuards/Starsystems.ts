import starsystemsCollection from "@/frontend/api/collections/Starsystems";
import { RouteLocationNormalized, NavigationGuardNext } from "vue-router";

export const starsystemRouteGuard = async function modelRouteGuard(
  to: RouteLocationNormalized,
  _from: RouteLocationNormalized,
  next: NavigationGuardNext
) {
  const response = await starsystemsCollection.findBySlug(
    String(to.params.slug)
  );

  if (!response.data) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default starsystemRouteGuard;
