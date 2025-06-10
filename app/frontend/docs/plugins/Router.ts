import { routes } from "@/docs/pages/routes";
import { createWebHistory } from "vue-router";
import { setupRouter } from "@/shared/plugins/Router";

const router = setupRouter({
  history: createWebHistory(window.ON_SUBDOMAIN ? "" : "/docs/"),
  routes,
});

export default router;
