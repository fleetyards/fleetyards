import { useAppStore } from "@/frontend/stores/app";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { type NavigationGuardNext, type RouteLocation } from "vue-router";
import { routes } from "@/frontend/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/shared/composables/useI18n";

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

  const { displayInfo } = useNoty();
  const { t } = useI18n();

  if (to.meta.needsNoAuthentication && sessionStore.isAuthenticated) {
    displayInfo({
      text: t("messages.session.alreadyLoggedIn"),
    });

    return {
      routeName: "home",
    };
  }

  if (to.meta.access && !sessionStore.hasAccessTo(to.meta.access)) {
    return {
      routeName: "403",
    };
  }
};

const router = setupRouter({
  beforeResolve,
  beforeEach,
  routes,
});

export default router;
