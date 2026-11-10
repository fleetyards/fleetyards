import "@/shared/polyfills";
import { createApp } from "vue";
import App from "@/docs/App.vue";
import router from "@/docs/plugins/Router";
import Tooltip from "@/shared/plugins/Tooltip";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { VueQueryPlugin } from "@tanstack/vue-query";

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

const app = createApp(App);

app.use(VueQueryPlugin);
app.use(router);
app.use(pinia);
app.use(Tooltip);

app.mount("#docs-app");
