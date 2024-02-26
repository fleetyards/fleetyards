import type { App } from "vue";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import { setupRules } from "@/frontend/validations";
import { configure } from "vee-validate";

export default {
  install: (_app: App<Element>, i18nComposable: () => I18nPluginOptions) => {
    const { t } = i18nComposable();

    configure({
      generateMessage: (context) => {
        return t(`validations.${context.rule?.name}`, {
          value: context.value,
          field: context.field,
        });
      },
    });

    setupRules(t);
  },
};
