import { checkEmail } from "@/services/fyApi";
import { debounce } from "ts-debounce";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const errorMessage = t("messages.error.emailTaken");

  const validate = debounce(async (value: string) => {
    try {
      const response = await checkEmail({
        value,
      });

      if (response.taken) {
        return true;
      }

      return errorMessage;
    } catch (error) {
      return errorMessage;
    }
  }, 100);

  return validate;
};
