import { createApp } from "vue";
import App from "@/frontend/App.vue";
import router from "@/frontend/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import i18n from "@/shared/plugins/I18n";
import noty from "@/shared/plugins/Noty";
import sentry from "@/shared/plugins/Sentry";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import VueLazyload from "vue-lazyload";
// import Subscriptions from "@/frontend/plugins/Subscriptions";
// import Ahoy from "@/frontend/plugins/Ahoy";
// import veeValidate from "@/shared/plugins/VeeValidate";
// import Validations from "@/frontend/plugins/Validations";
import { useI18n } from "@/frontend/composables/useI18n";
import { VueQueryPlugin } from "@tanstack/vue-query";

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

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

const app = createApp(App);

app.use(VueQueryPlugin);
app.use(router);
app.use(pinia);
app.use(sentry, router);
app.use(i18n, useI18n);
app.use(noty, useI18n);
app.use(VueLazyload);
app.use(FloatingVue);
// app.use(veeValidate, useI18n);
// app.use(Validations);
// app.use(Subscriptions);
// app.use(Ahoy);

app.mount("#app");
