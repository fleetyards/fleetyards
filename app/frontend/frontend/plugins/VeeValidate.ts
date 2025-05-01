import type { App } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { setupRules } from "@/frontend/validations";
import { configure } from "vee-validate";

export default {
  install: (_app: App<Element>) => {
    const { t } = useI18n();

    configure({
      generateMessage: (context) => {
        return t(`validations.${context.rule?.name}`, {
          value: context.value,
          field: context.field,
        });
      },
    });

    setupRules();
  },
};
