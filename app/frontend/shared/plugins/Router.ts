import {
  type LocationQueryValueRaw,
  createRouter,
  createWebHistory,
  type NavigationFailure,
  type RouteRecordRaw,
  type RouterHistory,
  type RouteLocationNormalized,
  type RouterOptions,
} from "vue-router";
import {
  chunkLoadFailures,
  claimPageLoadForFailedChunk,
  reloadForFailedChunk,
} from "@/shared/utils/ChunkReload";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { withoutTrailingSlash } from "@/shared/utils/Paths";
import { reportError } from "@/shared/plugins/Appsignal";
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
  afterEach?: (
    to: RouteLocationNormalized,
    from: RouteLocationNormalized,
    failure?: NavigationFailure | void,
  ) => void;
};

// A success that is about to time out on its own; a notice that waits for the
// member would hold a reload back for as long as it is left open.
export const successOnScreen = () =>
  useNotificationsStore().messages.some(
    (message) =>
      message.visible &&
      message.type === MessageTypesEnum.SUCCESS &&
      !message.persist &&
      message.timeout !== false,
  );

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

  router.afterEach((to, from, failure) => {
    options.afterEach?.(to, from, failure);

    // A document with a failed chunk is reloaded on arriving at another page.
    // After the navigation rather than before it, so a push, a replace and a Back
    // have already left history as they should.
    if (
      !failure &&
      chunkLoadFailures.value &&
      from.matched.length &&
      withoutTrailingSlash(to.path) !== withoutTrailingSlash(from.path) &&
      !("secret" in to.query) &&
      !successOnScreen() &&
      claimPageLoadForFailedChunk()
    ) {
      window.location.reload();
    }
  });

  router.onError((error, to) => {
    if (
      process.env.NODE_ENV === "production" &&
      (error.message.includes("Failed to fetch dynamically imported module") ||
        error.message.includes("error loading dynamically imported module") ||
        error.message.includes("Importing a module script failed"))
    ) {
      if (reloadForFailedChunk()) return;

      reportError(error, "router chunk load");

      // The page never arrived, so only a load of the address itself can get
      // there. Never of the address this document was loaded from, as that is
      // what would loop when the chunk fails on every load.
      const target = router.resolve(to).href;
      if (
        !("secret" in to.query) &&
        target !== `${window.location.pathname}${window.location.search}` &&
        claimPageLoadForFailedChunk()
      ) {
        window.location.assign(target);
      }
    }
  });

  return router;
};
