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
import veeValidate from "@/admin/plugins/VeeValidate";
import { VueQueryPlugin } from "@tanstack/vue-query";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

console.info(`API Endpoint: ${window.ADMIN_API_ENDPOINT}`);

const app = createApp(App);

app.use(VueQueryPlugin);
app.use(router);
app.use(pinia);
app.use(sentry, router);
app.use(i18n);
app.use(noty);
app.use(VueLazyload);
app.use(veeValidate);
app.use(FloatingVue);

app.mount("#app");
