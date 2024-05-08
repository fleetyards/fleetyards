import { useAppStore } from "@/frontend/stores/app";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { type NavigationGuardNext, type RouteLocation } from "vue-router";
import { routes } from "@/frontend/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";

const beforeEach = (
  to: RouteLocation,
  _from: RouteLocation,
  next: NavigationGuardNext,
) => {
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

  next();
};

const beforeResolve = (to: RouteLocation): FyRedirectRoute | undefined => {
  const sessionStore = useSessionStore();

  if (to.meta.needsAuthentication && !sessionStore.isAuthenticated) {
    return {
      routeName: "login",
      routeQuery: {
        redirectTo: String(to.fullPath),
      },
    };
  }
};

const router = setupRouter({
  beforeResolve,
  beforeEach,
  routes,
});

export default router;
