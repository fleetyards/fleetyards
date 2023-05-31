import { routes as initialRoutes } from "@/frontend/routes";
import { useAppStore } from "@/frontend/stores/App";
import { useFleetStore } from "@/frontend/stores/Fleet";
import { useSessionStore } from "@/frontend/stores/Session";
import type { Pinia } from "pinia";
import qs from "qs";
import Router from "vue-router";

const addTrailingSlashToAllRoutes = (routes) =>
  [].concat(
    ...routes.map((route) => {
      if (["*", "/"].includes(route.path)) {
        return [route];
      }

      const { pathToRegexpOptions = {} } = route;

      const path = route.path.replace(/\/$/, "");

      const modifiedRoute = {
        ...route,
        pathToRegexpOptions: {
          ...pathToRegexpOptions,
          strict: true,
        },
        path: `${path}/`,
      };

      if (route.children && route.children.length > 0) {
        modifiedRoute.children = addTrailingSlashToAllRoutes(route.children);
      }

      return [
        modifiedRoute,
        {
          path,
          redirect: (to) => ({
            name: route.name,
            params: to.params || null,
            query: to.query || null,
          }),
        },
      ];
    })
  );

const router = new Router({
  mode: "history",
  linkActiveClass: "active",
  linkExactActiveClass: "active-exact",

  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve, reject) => {
      setTimeout(() => {
        if (to.hash) {
          reject();
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ x: 0, y: 0 });
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

const setupRouter = (pinia: Pinia) => {
  const appStore = useAppStore(pinia);
  const sessionStore = useSessionStore(pinia);
  const fleetStore = useFleetStore(pinia);

  const validateAndResolveNewRoute = (to) => {
    if (to.meta.needsAuthentication && !sessionStore.isAuthenticated) {
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
    const newLocale = navigator.language;
    if (!appStore.locale || appStore.locale !== newLocale) {
      appStore.locale = newLocale;
    }

    if (to.name === "fleet-invite") {
      fleetStore.saveInviteToken(to.params.token);
    }

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

  return router;
};

export default setupRouter;
