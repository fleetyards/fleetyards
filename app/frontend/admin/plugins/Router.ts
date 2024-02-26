import qs from "qs";
import { routes as initialRoutes } from "@/admin/routes";
import { createRouter, createWebHistory } from "vue-router";
import type { LocationQuery } from "vue-router";
import { addTrailingSlashToAllRoutes } from "@/shared/utils/RouterHelper";

const router = createRouter({
  history: createWebHistory(window.ON_SUBDOMAIN ? "" : "/admin/"),
  linkActiveClass: "active",
  linkExactActiveClass: "active",

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

export default router;
