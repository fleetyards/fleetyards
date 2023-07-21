import { useComlink } from "@/shared/composables/useComlink";

export default {
  install(Vue: any) {
    const Bus = useComlink();

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$comlink = Bus;
  },
};
