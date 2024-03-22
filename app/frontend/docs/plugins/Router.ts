import qs from "qs";
import { routes as initialRoutes } from "@/docs/routes";
import { createRouter, createWebHistory } from "vue-router";
import type { LocationQuery } from "vue-router";
import { addTrailingSlashToAllRoutes } from "@/shared/utils/RouterHelper";

const router = createRouter({
  history: createWebHistory(window.ON_SUBDOMAIN ? "" : "/docs/"),
  linkActiveClass: "active",
  linkExactActiveClass: "active-exact",

  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
      setTimeout(() => {
        if (to.hash) {
          resolve({ el: to.hash });
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ top: 0, left: 0 });
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
