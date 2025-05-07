import VueLazyload from "vue-lazyload";
import AppV1 from "@/embed/AppV1.vue";
import router from "@/embed/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

setTimeout(() => {
  const app = createApp(AppV1);

  app.use(router);
  app.use(pinia);
  app.use(VueLazyload);

  app.use(FloatingVue, {
    container: "#fleetyards-view",
  });

  app.mount("#fleetyards-view");

  window.FleetYardsFleetchart = app;
}, 2000);
