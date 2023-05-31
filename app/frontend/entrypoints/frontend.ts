import App from "@/frontend/App.vue";
import ApiClient from "@/frontend/api/client";
import I18nPlugin from "@/frontend/lib/I18n";
import router from "@/frontend/lib/Router";
import "@/frontend/lib/Sentry";
import store from "@/frontend/lib/Store";
import Comlink from "@/frontend/plugins/Comlink";
import "@/frontend/plugins/LazyLoad";
import pinia from "@/frontend/plugins/Pinia";
import Subscriptions from "@/frontend/plugins/Subscriptions";
import Validations from "@/frontend/plugins/Validations";
import VTooltip from "v-tooltip";
import Vue from "vue";

Vue.use(Subscriptions);
Vue.use(ApiClient);
Vue.use(Comlink);
Vue.use(I18nPlugin);
Vue.use(Validations);

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

if (process.env.NODE_ENV !== "production") {
  Vue.config.devtools = true;
} else {
  Vue.config.productionTip = false;
}

VTooltip.enabled = window.innerWidth > 768;
Vue.use(VTooltip);

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
});

if (store.state.storeVersion !== window.STORE_VERSION) {
  console.info("Updating Store Version and resetting Store");

  store.dispatch("reset");
  store.commit("setStoreVersion", window.STORE_VERSION);
}

// eslint-disable-next-line no-new
new Vue({
  el: "#app",
  router,
  store,
  pinia,
  render: (h) => h(App),
});
