import Vue from "vue";
import App from "@/docs/App.vue";
import router from "@/docs/plugins/Router";
import "@/frontend/plugins/LazyLoad";
import VTooltip from "v-tooltip";

if (process.env.NODE_ENV !== "production") {
  Vue.config.devtools = true;
} else {
  Vue.config.productionTip = false;
}

Vue.use(VTooltip);

document.addEventListener("DOMContentLoaded", () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: "#docs-app",
    router,
    render: (h) => h(App),
  });
});
