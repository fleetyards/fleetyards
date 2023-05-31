import App from "@/admin/App.vue";
import router from "@/admin/lib/Router";
import store from "@/admin/lib/Store";
import ApiClient from "@/frontend/api/client";
import I18nPlugin from "@/frontend/lib/I18n";
import "@/frontend/lib/Sentry";
import Comlink from "@/frontend/plugins/Comlink";
import "@/frontend/plugins/LazyLoad";
import Validations from "@/frontend/plugins/Validations";
import VTooltip from "v-tooltip";
import Vue from "vue";

Vue.use(ApiClient);
Vue.use(Comlink);
Vue.use(I18nPlugin);
Vue.use(Validations);

declare global {
  interface Window {
    API_ENDPOINT: string;
    ON_SUBDOMAIN: boolean;
  }
}

if (process.env.NODE_ENV !== "production") {
  Vue.config.devtools = true;
} else {
  Vue.config.productionTip = false;
}

VTooltip.enabled = window.innerWidth > 768;
Vue.use(VTooltip);

console.info(`API Endpoint: ${window.API_ENDPOINT}`);

document.addEventListener("DOMContentLoaded", () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: "#app",
    router,
    store,
    render: (h) => h(App),
  });
});
