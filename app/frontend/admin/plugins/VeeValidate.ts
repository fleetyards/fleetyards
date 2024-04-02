import type { App } from "vue";
import { setupRules } from "@/admin/validations";
import { configure } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";

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
