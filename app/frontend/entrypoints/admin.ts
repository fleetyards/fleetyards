import App from "@/admin/App.vue";
import router from "@/admin/plugins/Router";
import Comlink from "@/frontend/plugins/Comlink";
import "@/frontend/plugins/LazyLoad";
import setupSentry from "@/frontend/plugins/Sentry";
import Validations from "@/frontend/plugins/Validations";
import VTooltip from "v-tooltip";
import { createApp } from "vue";

const app = createApp(App);

setupSentry(app, router);

app.use(Comlink);
app.use(Validations);
app.use(router);

declare global {
  interface Window {
    API_ENDPOINT: string;
    ON_SUBDOMAIN: boolean;
  }
}

VTooltip.enabled = window.innerWidth > 768;
app.use(VTooltip);

console.info(`API Endpoint: ${window.API_ENDPOINT}`);

app.mount("#app");
