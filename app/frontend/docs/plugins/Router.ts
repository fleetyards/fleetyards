import Vue from "vue";
import Router from "vue-router";
import type { Route, RouteConfig } from "vue-router";
import qs from "qs";
import { routes as initialRoutes } from "@/docs/routes";

Vue.use(Router);

const addTrailingSlashToAllRoutes = (routes: RouteConfig[]): RouteConfig[] =>
  ([] as RouteConfig[]).concat(
    ...routes.map((route: RouteConfig): RouteConfig[] => {
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
          redirect: (to: Route) => ({
            name: route.name,
            params: to.params || undefined,
            query: to.query || undefined,
          }),
        },
      ];
    }),
  );

const router = new Router({
  mode: "history",
  base: window.ON_SUBDOMAIN ? "" : "/docs/",
  linkActiveClass: "active",
  linkExactActiveClass: "active-exact",

  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
      setTimeout(() => {
        if (to.hash) {
          resolve({ selector: to.hash });
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
