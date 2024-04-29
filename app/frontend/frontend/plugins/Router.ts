import { createRouter, createWebHistory } from "vue-router";
import type {
  RouteLocation,
  LocationQuery,
  LocationQueryValueRaw,
} from "vue-router";
import qs from "qs";
import { useAppStore } from "@/frontend/stores/app";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { routes as initialRoutes } from "@/frontend/pages/routes";
import { addTrailingSlashToAllRoutes } from "@/shared/utils/RouterHelper";

// To ensure it is treated as a module, add at least one `export` statement
export {};

export type FyLocartionQueryValue = Record<
  string,
  string | number | boolean | null | undefined
>;

export type FyLocationQuery = Record<
  string | number,
  LocationQueryValueRaw | LocationQueryValueRaw[] | FyLocartionQueryValue
>;

type RedirectRoute = {
  routeName: string;
  routeParams?: Record<string, string>;
  routeQuery?: Record<string, string>;
};

const router = createRouter({
  history: createWebHistory(),
  linkActiveClass: "active",
  linkExactActiveClass: "active-exact",

  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
      setTimeout(() => {
        if (to.hash) {
          resolve(false);
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ left: 0, top: 0 });
        }
      }, 600);
    }),

  parseQuery(query) {
    return qs.parse(query) as LocationQuery;
  },

  stringifyQuery(query) {
    const result = qs.stringify(query, { arrayFormat: "brackets" });
    return result ? `${result}` : "";
  },

  routes: addTrailingSlashToAllRoutes(initialRoutes),
});

const validateAndResolveNewRoute = (
  to: RouteLocation,
): RedirectRoute | undefined => {
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

router.beforeResolve((to, _from, next) => {
  const newRoute = validateAndResolveNewRoute(to);
  if (newRoute) {
    router
      .push({
        name: newRoute.routeName,
        params: newRoute.routeParams,
        query: newRoute.routeQuery,
      })
      .catch(() => {
        window.location.reload();
      });
  } else {
    next();
  }
});

router.beforeEach((to, _from, next) => {
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
});

router.onError((error) => {
  if (
    process.env.NODE_ENV === "production" &&
    (error.message.includes("Failed to fetch dynamically imported module") ||
      error.message.includes("error loading dynamically imported module") ||
      error.message.includes("Importing a module script failed"))
  ) {
    // window.location = to.fullPath; TODO: switch once vue-router >= 4
    window.location.reload();
  }
});

export default router;
