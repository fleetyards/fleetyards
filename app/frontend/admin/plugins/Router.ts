import { useSessionStore } from "@/admin/stores/session";
import { createWebHistory, type RouteLocation } from "vue-router";
import { routes } from "@/admin/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";

const beforeResolve = (to: RouteLocation): FyRedirectRoute | undefined => {
  const sessionStore = useSessionStore();

  if (to.name != "admin-login" && !sessionStore.isAuthenticated) {
    return {
      routeName: "admin-login",
      routeQuery: {
        redirectTo: String(to.fullPath),
      },
    };
  }
};

const router = setupRouter({
  history: createWebHistory(window.ON_SUBDOMAIN ? "" : "/admin/"),
  beforeResolve,
  routes,
});

export default router;
