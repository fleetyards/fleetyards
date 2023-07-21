import type { App } from "vue";
import { i18nHelpers } from "@/shared/utils/I18nHelpers";
import type { TranslateOptions, Scope } from "i18n-js";

export interface I18nPluginOptions extends ReturnType<typeof i18nHelpers> {
  t: (scope: Scope, options?: TranslateOptions) => string;
  currentLocale: () => string;
}

export default {
  install: (app: App<Element>, i18nComposable: () => I18nPluginOptions) => {
    const { t, currentLocale, l, toNumber, toUEC, toDollar, toAu } =
      i18nComposable();

    app.provide<I18nPluginOptions>("i18n", {
      t,
      currentLocale,
      l,
      toNumber,
      toUEC,
      toDollar,
      toAu,
    });
  },
};
