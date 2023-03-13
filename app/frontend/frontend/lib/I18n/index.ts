import useI18nHelpers from "@/frontend/composables/useI18nHelpers";

const { I18n, t, l, toNumber, toDollar, toAu, toUEC, availableLocales } =
  useI18nHelpers();

export { I18n };

export default {
  // tslint:disable-next-line variable-name
  install(Vue: any) {
    Vue.prototype.$availableLocales = availableLocales;
    Vue.prototype.$t = t;
    Vue.prototype.$l = l;
    Vue.prototype.$toNumber = toNumber;
    Vue.prototype.$toDollar = toDollar;
    Vue.prototype.$toAu = toAu;
    Vue.prototype.$toUEC = toUEC;
  },
};
