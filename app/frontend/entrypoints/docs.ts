import { createApp } from "vue";
import App from "@/docs/App.vue";
import router from "@/docs/plugins/Router";
import FloatingVue from "floating-vue";
import i18n from "@/shared/plugins/I18n";
import "floating-vue/dist/style.css";
import VueLazyload from "vue-lazyload";
import VueHighlightJS from "vue3-highlightjs";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { VueQueryPlugin } from "@tanstack/vue-query";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

const app = createApp(App);

app.use(VueQueryPlugin);
app.use(router);
app.use(VueLazyload);
app.use(pinia);
app.use(i18n);
app.use(FloatingVue);
app.use(VueHighlightJS);

app.mount("#docs-app");
