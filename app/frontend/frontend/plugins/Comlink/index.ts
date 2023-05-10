import { useComlink } from "@/frontend/composables/useComlink";

export default {
  install(Vue) {
    const Bus = useComlink();

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$comlink = Bus;
  },
};
