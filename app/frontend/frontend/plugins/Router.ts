import { useAppStore } from "@/frontend/stores/app";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { type RouteLocation } from "vue-router";
import { routes } from "@/frontend/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";
import { queryClient } from "@/frontend/plugins/QueryClient";
import { featuresQueryOptions } from "@/frontend/composables/useFeatures";
import type { FeatureFlagName } from "@/services/fyApi";

const beforeEach = (to: RouteLocation) => {
  const fleetStore = useFleetStore();
  if (to.name === "fleet-invite" && to.params.token) {
    fleetStore.inviteToken = String(to.params.token);
  }

  const appStore = useAppStore();
  // check if update is available
  if (
    appStore.isUpdateAvailable &&
    Object.keys(to.query).length === 0 &&
    to.query.constructor === Object &&
    Object.keys(to.params).length === 0 &&
    to.params.constructor === Object
  ) {
    window.location.href = to.path;
    return;
  }
};

// A route behind a flag that is off does not exist for this user: hiding it
// from the nav is not enough, a typed-in URL has to land on the 404 rather than
// render a page whose every request comes back 403.
const featureEnabled = async (feature: FeatureFlagName) => {
  try {
    const features = await queryClient.ensureQueryData(featuresQueryOptions());

    return !!features?.includes(feature);
  } catch {
    // The endpoint is also what the nav reads, so a failure here is already
    // visible. Let the navigation through and leave the API as the real gate
    // rather than 404-ing pages the user may well have access to.
    return true;
  }
};

export const beforeResolve = async (
  to: RouteLocation,
): Promise<FyRedirectRoute | undefined> => {
  const sessionStore = useSessionStore();

  if (to.meta.needsAuthentication && !sessionStore.isAuthenticated) {
    const redirectBackStore = useRedirectBackStore();
    redirectBackStore.setBackRoute(to);

    return {
      routeName: "login",
    };
  }

  if (to.meta.needsNoAuthentication && sessionStore.isAuthenticated) {
    return {
      routeName: "home",
    };
  }

  // After the session checks: flags are read per user, so signing in first is
  // what makes the answer meaningful.
  if (to.meta.feature && !(await featureEnabled(to.meta.feature))) {
    return {
      routeName: "404",
    };
  }
};

const router = setupRouter({
  beforeResolve,
  beforeEach,
  routes,
});

export default router;
