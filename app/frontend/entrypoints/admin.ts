import { createApp } from "vue";
import App from "@/admin/App.vue";
import router from "@/admin/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import sentry from "@/shared/plugins/Sentry";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import VueLazyload from "vue-lazyload";
import veeValidate from "@/admin/plugins/VeeValidate";
import {
  VueQueryPlugin,
  type VueQueryPluginOptions,
} from "@tanstack/vue-query";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

console.info(`API Endpoint: ${window.ADMIN_API_ENDPOINT}`);

const app = createApp(App);

const vueQueryPluginOptions: VueQueryPluginOptions = {
  queryClientConfig: {
    defaultOptions: {
      queries: {
        retry: 1,
        refetchOnWindowFocus: false,
      },
    },
  },
};

app.use(VueQueryPlugin, vueQueryPluginOptions);
app.use(router);
app.use(pinia);
app.use(sentry, router);
app.use(VueLazyload);
app.use(veeValidate);
app.use(FloatingVue);

app.mount("#app");
