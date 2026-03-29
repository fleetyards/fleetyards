import { createApp } from "vue";
import App from "@/frontend/App.vue";
import router from "@/frontend/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { setupAppsignal } from "@/shared/plugins/Appsignal";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import VueLazyload from "vue-lazyload";
import veeValidate from "@/frontend/plugins/VeeValidate";
import {
  VueQueryPlugin,
  type VueQueryPluginOptions,
} from "@tanstack/vue-query";

document.addEventListener("DOMContentLoaded", () => {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker
      .register("/sw.js", {
        scope: "/",
      })
      .then(
        (registration) => {
          // Registration was successful
          console.info(
            "ServiceWorker registration successful with scope: ",
            registration.scope,
          );
        },
        (err) => {
          // registration failed :(
          console.error("ServiceWorker registration failed: ", err);
        },
      );
  }
});

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

const app = createApp(App);

const vueQueryPluginOptions: VueQueryPluginOptions = {
  enableDevtoolsV6Plugin: true,
  queryClientConfig: {
    defaultOptions: {
      queries: {
        placeholderData: (prev: unknown) => prev,
        retry: 1,
        refetchOnWindowFocus: false,
      },
    },
  },
};

app.use(VueQueryPlugin, vueQueryPluginOptions);
app.use(router);
app.use(pinia);
setupAppsignal(app);
app.use(VueLazyload);
app.use(FloatingVue);
app.use(veeValidate);

app.mount("#app");
