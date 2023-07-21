import { createApp } from "vue";
import App from "@/frontend/App.vue";
import store from "@/frontend/lib/Store";
import "@/frontend/plugins/LazyLoad";
import "@/frontend/lib/Sentry";
import ApiClient from "@/frontend/api/client";
import Subscriptions from "@/frontend/plugins/Subscriptions";
import Comlink from "@/frontend/plugins/Comlink";
import Ahoy from "@/frontend/plugins/Ahoy";
import Validations from "@/frontend/plugins/Validations";
import VTooltip from "v-tooltip";
import VShowSlide from "v-show-slide";
import i18n from "@/frontend/plugins/I18n";
import router from "@/frontend/plugins/Router";

declare global {
  interface Window {
    APP_VERSION: string;
    STORE_VERSION: string;
    SC_DATA_VERSION: string;
    APP_CODENAME: string;
    API_VERSION: string;
    API_OAS_VERSION: string;
    API_ENDPOINT: string;
    DATA_PREFILL: KeyValuePair;
    FRONTEND_ENDPOINT: string;
    CABLE_ENDPOINT: string;
  }
}

document.addEventListener("DOMContentLoaded", () => {
  if ("serviceWorker" in navigator) {
    // eslint-disable-next-line compat/compat
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

  if (store.state.storeVersion !== window.STORE_VERSION) {
    console.info("Updating Store Version and resetting Store");

    store.dispatch("reset");
    store.commit("setStoreVersion", window.STORE_VERSION);
  }
});

const app = createApp(App);

app.use(router);
app.use(i18n);
// TODO: migrate to pinia
// app.use(store);

VTooltip.enabled = window.innerWidth > 768;
app.use(VTooltip);

app.use(VShowSlide);
app.use(Subscriptions);
app.use(ApiClient);
app.use(Comlink);
// TODO: migrate to vue-i18n
// app.use(I18nPlugin);
app.use(Ahoy);
app.use(Validations);

app.mount("#app");
