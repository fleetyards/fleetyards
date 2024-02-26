import { I18n } from "i18n-js";
import type { TranslateOptions, Scope } from "i18n-js";
import translations from "@/admin/translations";
import { i18nHelpers } from "@/shared/utils/I18nHelpers";
import { useI18nStore } from "@/shared/stores/i18n";

const i18n = new I18n(translations);

i18n.availableLocales = ["en"];
i18n.defaultLocale = "en";

i18n.enableFallback = true;

export const useI18n = () => {
  const i18nStore = useI18nStore();

  if (i18nStore.locale) {
    i18n.locale = i18nStore.locale;
  }

  watch(
    () => i18nStore.locale,
    (locale) => {
      i18n.locale = locale;
    },
  );

  return {
    t: (scope: Scope, options?: TranslateOptions) => i18n.t(scope, options),
    currentLocale: () => i18n.locale,
    ...i18nHelpers(i18n),
  };
};
