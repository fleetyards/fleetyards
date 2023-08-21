import type { App } from "vue";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import { setupRules } from "@/shared/validations";
import { configure } from "vee-validate";

export default {
  install: (_app: App<Element>, i18nComposable: () => I18nPluginOptions) => {
    const { t, currentLocale } = i18nComposable();

    configure({
      generateMessage: (context) => {
        return t(`validations.${context.rule}`, {
          value: context.value,
          field: context.field,
        });
      },
    });

    setupRules(t, currentLocale);
  },
};
