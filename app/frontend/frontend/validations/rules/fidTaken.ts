import { checkFID } from "@/services/fyApi";
import { debounce } from "ts-debounce";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const errorMessage = t("messages.error.fleetTaken");

  const validate = debounce(async (value: string) => {
    try {
      const response = await checkFID({
        value,
      });

      if (response.taken) {
        return errorMessage;
      }

      return true;
    } catch (error) {
      return errorMessage;
    }
  }, 100);

  return validate;
};
