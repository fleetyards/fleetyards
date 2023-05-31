import { routes } from "@/admin/routes";
import qs from "qs";
import { createRouter, createWebHistory } from "vue-router";

const router = createRouter({
  history: createWebHistory(),
  base: window.ON_SUBDOMAIN ? "" : "/admin",
  linkActiveClass: "active",
  linkExactActiveClass: "active",
  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
      setTimeout(() => {
        if (to.hash) {
          resolve();
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ x: 0, y: 0 });
        }
      }, 600);
    }),
  routes,
  parseQuery: qs.parse,
  stringifyQuery(query) {
    const result = qs.stringify(query);
    return result ? `?${result}` : "";
  },
});

export default router;
