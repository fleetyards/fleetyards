import { createPinia, PiniaVuePlugin } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import Vue from "vue";

Vue.use(PiniaVuePlugin);

const pinia = createPinia();
pinia.use(piniaPluginPersistedstate);

export default pinia;
