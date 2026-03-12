import type { App } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { setupRules } from "@/frontend/validations";
import { configure } from "vee-validate";

export default {
  install: (_app: App<Element>) => {
    const { t } = useI18n();

    configure({
      generateMessage: (context) => {
        const params = Array.isArray(context.rule?.params)
          ? { min: context.rule?.params[0], max: context.rule?.params[1] }
          : context.rule?.params || {};

        return t(`validations.${context.rule?.name}`, {
          value: context.value,
          field: context.field,
          ...params,
        });
      },
    });

    setupRules();
  },
};
