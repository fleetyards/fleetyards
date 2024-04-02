import type { App } from "vue";
import { i18nHelpers } from "@/shared/utils/I18nHelpers";
import { useI18n } from "@/shared/composables/useI18n";
import type { TranslateOptions, Scope } from "i18n-js";
import { useI18n } from "@/shared/composables/useI18n";

export interface I18nPluginOptions extends ReturnType<typeof i18nHelpers> {
  t: (scope: Scope, options?: TranslateOptions) => string;
  currentLocale: () => string;
}

export default {
  install: (app: App<Element>) => {
    const { t, currentLocale, l, toNumber, toUEC, toDollar, toAu } = useI18n();

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
