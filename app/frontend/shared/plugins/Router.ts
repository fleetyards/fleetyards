import {
  type LocationQueryValueRaw,
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
  type RouterHistory,
  type RouteLocationNormalized,
  type NavigationGuardNext,
} from "vue-router";
import { type LocationQuery } from "vue-router";
import qs from "qs";

export type FyLocartionQueryValue = Record<
  string,
  string | number | boolean | null | undefined
>;

export type FyLocationQuery = Record<
  string | number,
  LocationQueryValueRaw | LocationQueryValueRaw[] | FyLocartionQueryValue
>;

export type FyRedirectRoute = {
  routeName: string;
  routeParams?: Record<string, string>;
  routeQuery?: Record<string, string>;
};

export type FyRouterOptions = {
  routes: RouteRecordRaw[];
  history?: RouterHistory;
  // linkActiveClass?: string;
  // linkExactActiveClass?: string;
  // scrollBehavior?: (
  //   to: RouteLocationNormalized,
  //   from: RouteLocationNormalized,
  //   savedPosition: ScrollToPosition | void,
  // ) => Promise<ScrollToPosition>;
  // parseQuery?: (query: string) => LocationQuery;
  // stringifyQuery?: (query: LocationQuery) => string;
  beforeResolve?: (to: RouteLocationNormalized) => FyRedirectRoute | undefined;
  beforeEach?: (
    to: RouteLocationNormalized,
    from: RouteLocationNormalized,
    next: NavigationGuardNext,
  ) => void;
};

export const setupRouter = (options: FyRouterOptions) => {
  const router = createRouter({
    history: options.history || createWebHistory(),
    linkActiveClass: "active",
    linkExactActiveClass: "active-exact",

    scrollBehavior: (to, _from, savedPosition) =>
      new Promise((resolve) => {
        if (to.hash) {
          resolve({ el: to.hash, behavior: "smooth" });
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ left: 0, top: 0 });
        }
      }),

    parseQuery(query) {
      return qs.parse(query) as LocationQuery;
    },

    stringifyQuery(query) {
      const result = qs.stringify(query, { arrayFormat: "brackets" });
      return result ? `${result}` : "";
    },

    routes: options?.routes || [],
  });

  router.beforeResolve((to, _from, next) => {
    if (!options?.beforeResolve) {
      next();
      return;
    }

    const newRoute = options.beforeResolve(to);
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
    if (!options?.beforeEach) {
      next();
      return;
    }

    options.beforeEach(to, _from, next);
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

  return router;
};
