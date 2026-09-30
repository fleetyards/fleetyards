import { createApp, defineAsyncComponent } from "vue";
import App from "@/frontend/App.vue";
import router from "@/frontend/plugins/Router";
import { queryClient } from "@/frontend/plugins/QueryClient";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { setupAppsignal } from "@/shared/plugins/Appsignal";
import Tooltip from "@/shared/plugins/Tooltip";
import { MARKDOWN_CATALOGUE_TOKEN } from "@/shared/components/Markdown/catalogueTokens";
import veeValidate from "@/frontend/plugins/VeeValidate";
import {
  VueQueryPlugin,
  type VueQueryPluginOptions,
} from "@tanstack/vue-query";
import { captureInstallPrompt } from "@/frontend/composables/useInstallPrompt";

captureInstallPrompt();

window.addEventListener("vite:preloadError", (event) => {
  event.preventDefault();
  window.location.reload();
});

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
  queryClient,
};

app.use(VueQueryPlugin, vueQueryPluginOptions);
app.use(router);
app.use(pinia);
setupAppsignal(app);
app.use(Tooltip);
app.use(veeValidate);
// Items named inline in markdown, `[*Name*]`, link to their page and show
// their stats card. Loaded with the first text that names one.
app.provide(
  MARKDOWN_CATALOGUE_TOKEN,
  defineAsyncComponent(
    () => import("@/frontend/components/CatalogueTokenLink/index.vue"),
  ),
);

app.mount("#app");
