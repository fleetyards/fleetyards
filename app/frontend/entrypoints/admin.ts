import { createApp } from "vue";
import App from "@/admin/App.vue";
import router from "@/admin/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import i18n from "@/shared/plugins/I18n";
import noty from "@/shared/plugins/Noty";
import sentry from "@/shared/plugins/Sentry";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import VueLazyload from "vue-lazyload";
// import veeValidate from "@/shared/plugins/VeeValidate";
import { useI18n } from "@/admin/composables/useI18n";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

console.info(`API Endpoint: ${window.API_ENDPOINT}`);

const app = createApp(App);

app.use(router);
app.use(pinia);
app.use(sentry, router);
app.use(i18n, useI18n);
app.use(noty, useI18n);
app.use(VueLazyload);
// app.use(veeValidate, useI18n);
app.use(FloatingVue);

app.mount("#app");
