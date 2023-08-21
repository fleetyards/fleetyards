import modelsCollection from "@/frontend/api/collections/Models";

import { RouteLocation, NavigationGuardNext } from "vue-router";

export const modelRouteGuard = async function modelRouteGuard(
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext
) {
  const model = await modelsCollection.findBySlug(String(to.params.slug));

  if (!model) {
    next({ name: "404" });
  } else {
    next();
  }
};

export default modelRouteGuard;
