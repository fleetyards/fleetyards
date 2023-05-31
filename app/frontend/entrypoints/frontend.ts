import App from "@/frontend/App.vue";
import "@/frontend/plugins/LazyLoad";
import pinia from "@/frontend/plugins/Pinia";
import router from "@/frontend/plugins/Router";
import setupSentry from "@/frontend/plugins/Sentry";
import Validations from "@/frontend/plugins/Validations";
import VTooltip from "v-tooltip";
import { createApp } from "vue";
import { VueQueryPlugin } from "vue-query";

declare global {
  interface Window {
    APP_NAME: string;
    APP_VERSION: string;
    STORE_VERSION: string;
    SC_DATA_VERSION: string;
    APP_CODENAME: string;
    API_ENDPOINT: string;
    DATA_PREFILL: KeyValuePair;
    FRONTEND_ENDPOINT: string;
    CABLE_ENDPOINT: string;
    GIT_REVISION: string;
    SENTRY_DSN: string;
    NODE_ENV: string;
  }
}
const app = createApp(App);

setupSentry(app, router);

app.use(VueQueryPlugin);
app.use(Validations);
app.use(pinia);
app.use(router);

VTooltip.enabled = window.innerWidth > 768;
app.use(VTooltip);

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
            registration.scope
          );
        },
        (err) => {
          // registration failed :(
          console.error("ServiceWorker registration failed: ", err);
        }
      );
  }
});

// if (store.state.storeVersion !== window.STORE_VERSION) {
//   console.info("Updating Store Version and resetting Store");

//   store.dispatch("reset");
//   store.commit("setStoreVersion", window.STORE_VERSION);
// }

app.mount("#app");
