import { createApp } from "vue";
import App from "@/admin/App.vue";
import router from "@/admin/plugins/Router";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { setupAppsignal } from "@/shared/plugins/Appsignal";
import Tooltip from "@/shared/plugins/Tooltip";
import veeValidate from "@/admin/plugins/VeeValidate";
import {
  VueQueryPlugin,
  type VueQueryPluginOptions,
} from "@tanstack/vue-query";

window.addEventListener("vite:preloadError", (event) => {
  event.preventDefault();
  window.location.reload();
});

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

console.info(`API Endpoint: ${window.ADMIN_API_ENDPOINT}`);

const app = createApp(App);

const vueQueryPluginOptions: VueQueryPluginOptions = {
  queryClientConfig: {
    defaultOptions: {
      queries: {
        placeholderData: (prev: unknown) => prev,
        retry: 1,
        refetchOnWindowFocus: false,
      },
    },
  },
};

app.use(VueQueryPlugin, vueQueryPluginOptions);
app.use(router);
app.use(pinia);
setupAppsignal(app);
app.use(veeValidate);
app.use(Tooltip);

const mountApp = () => app.mount("#app");

// Not `mountApp()` on its own: the router resolves its first navigation
// asynchronously, so the first render would be the start location, where
// `route.name` is undefined and `route.meta` empty. Mounted on a rejected
// navigation as well, so a dead route chunk shows the app instead of leaving
// the intro splash up for good — `router.onError` reloads in production.
router.isReady().then(mountApp, mountApp);
