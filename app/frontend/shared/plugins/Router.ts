import {
  type LocationQueryValueRaw,
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
  type RouterHistory,
  type RouteLocationNormalized,
  type RouterOptions,
} from "vue-router";
import qs from "qs";
import { sameApartFromModalQuery } from "@/shared/utils/ModalQuery";
import { restoreSavedFilter } from "@/shared/stores/filters";

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
  beforeResolve?: (
    to: RouteLocationNormalized,
  ) => FyRedirectRoute | undefined | Promise<FyRedirectRoute | undefined>;
  beforeEach?: (to: RouteLocationNormalized) => void;
};

export const setupRouter = (options: FyRouterOptions) => {
  const router = createRouter({
    history: options.history || createWebHistory(),
    linkActiveClass: "active",
    linkExactActiveClass: "active-exact",

    scrollBehavior: (to, from, savedPosition) =>
      new Promise((resolve) => {
        // Opening or closing a query modal writes the address of the page the
        // visitor is already on. Nothing under the modal moves, so neither
        // does the scroll position -- checked before the hash, because that
        // page may well have one and it was already scrolled to.
        if (sameApartFromModalQuery(to, from)) {
          resolve(false);
        } else if (to.hash) {
          resolve({ el: to.hash, behavior: "smooth" });
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ left: 0, top: 0 });
        }
      }),

    // vue-router 5.4 types this option against the experimental array-only
    // query shape; the classic router still accepts the mixed shape at runtime.
    parseQuery(query) {
      return qs.parse(query) as unknown as ReturnType<
        NonNullable<RouterOptions["parseQuery"]>
      >;
    },

    stringifyQuery(query) {
      const result = qs.stringify(query, { arrayFormat: "brackets" });

      return result ? `${result}` : "";
    },

    routes: options?.routes || [],
  });

  router.beforeResolve(async (to) => {
    if (!options?.beforeResolve) {
      return;
    }

    const newRoute = await options.beforeResolve(to);
    if (newRoute) {
      return {
        name: newRoute.routeName,
        params: newRoute.routeParams,
        query: newRoute.routeQuery,
      };
    }
  });

  router.beforeEach(restoreSavedFilter);

  router.beforeEach((to) => {
    if (!options?.beforeEach) {
      return;
    }

    options.beforeEach(to);
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
