import { defineStore } from "pinia";
import {
  type RouteLocationResolved,
  type Router,
  type RouterLinkProps,
} from "vue-router";

type RedirectBackState = {
  backRoute?: RouterLinkProps["to"];
};

export const useRedirectBackStore = defineStore("redirectBack", {
  state: (): RedirectBackState => ({
    backRoute: undefined,
  }),
  actions: {
    setBackRoute(backRoute: RouterLinkProps["to"]) {
      this.backRoute = backRoute;
    },
    // The back route is persisted, so it can name a route a later release
    // renamed or removed. Resolving that throws; drop it instead, so it does
    // not break every sign-in that follows.
    resolveBackRoute(router: Router): RouteLocationResolved | undefined {
      if (!this.backRoute) {
        return undefined;
      }

      try {
        return router.resolve(this.backRoute);
      } catch {
        this.$reset();
        return undefined;
      }
    },
  },
  persist: true,
});
