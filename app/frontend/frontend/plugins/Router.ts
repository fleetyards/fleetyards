import { createRouter, createWebHistory } from "vue-router";
import type { RouteLocation } from "vue-router";
import qs from "qs";
import Store from "@/frontend/lib/Store";
import { routes as initialRoutes } from "@/frontend/routes";
import { addTrailingSlashToAllRoutes } from "@/shared/utils/RouterHelper";

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
    return qs.parse(query);
  },

  stringifyQuery(query) {
    const result = qs.stringify(query, { arrayFormat: "brackets" });
    return result ? `?${result}` : "";
  },

  routes: addTrailingSlashToAllRoutes(initialRoutes),
});

const validateAndResolveNewRoute = (to: RouteLocation) => {
  if (
    to.meta.needsAuthentication &&
    !Store.getters["session/isAuthenticated"]
  ) {
    return {
      routeName: "login",
      routeParams: {
        redirectToRoute: to.name,
      },
    };
  }
  return null;
};

router.beforeResolve((to, _from, next) => {
  const newRoute = validateAndResolveNewRoute(to);
  if (newRoute) {
    router
      .push({ name: newRoute.routeName, params: newRoute.routeParams })
      .catch(() => {
        window.location.reload();
      });
  } else {
    next();
  }
});

router.beforeEach((to, from, next) => {
  if (to.name === "fleet-invite") {
    Store.dispatch("fleet/saveInviteToken", to.params.token);
  }

  // check if update is available
  if (
    Store.getters["app/isUpdateAvailable"] &&
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
