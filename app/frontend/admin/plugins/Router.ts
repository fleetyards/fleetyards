import { useSessionStore } from "@/admin/stores/session";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { createWebHistory, type RouteLocation } from "vue-router";
import { routes } from "@/admin/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";

const beforeResolve = (to: RouteLocation): FyRedirectRoute | undefined => {
  const sessionStore = useSessionStore();

  if (to.name != "admin-login" && !sessionStore.isAuthenticated) {
    const redirectBackStore = useRedirectBackStore();
    redirectBackStore.backRoute = to;

    return {
      routeName: "admin-login",
    };
  }
};

const router = setupRouter({
  history: createWebHistory(window.ON_SUBDOMAIN ? "" : "/admin/"),
  beforeResolve,
  routes,
});

export default router;
