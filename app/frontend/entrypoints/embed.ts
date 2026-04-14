import AppV1 from "@/embed/AppV1.vue";
import router from "@/embed/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import Tooltip from "@/shared/plugins/Tooltip";
import { VueQueryPlugin } from "@tanstack/vue-query";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

setTimeout(() => {
  const app = createApp(AppV1);

  app.use(router);
  app.use(pinia);
  app.use(VueQueryPlugin);

  app.use(Tooltip);

  app.mount("#fleetyards-view");

  window.FleetYardsFleetchart = app;
}, 2000);
