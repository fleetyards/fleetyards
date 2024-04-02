import VueLazyload from "vue-lazyload";
import App from "@/embed/App.vue";
import router from "@/embed/plugins/Router";
import i18n from "@/shared/plugins/I18n";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

window.FleetYardsFleetchart = undefined;

setTimeout(() => {
  window.FleetYardsFleetchartConfig ||= {};

  const app = createApp(App);

  app.use(router);
  app.use(pinia);
  app.use(i18n);
  app.use(VueLazyload);
  app.use(FloatingVue, {
    container: "#fleetyards-view",
  });

  app.mount("#fleetyards-view");

  window.FleetYardsFleetchart = app;
}, 2000);
