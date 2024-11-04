import { useApiClient } from "@/frontend/composables/useApiClient";
import { debounce } from "ts-debounce";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const { fleets: fleetsService } = useApiClient();

  const errorMessage = t("messages.error.fleetTaken");

  const validate = debounce(async (value: string) => {
    return fleetsService
      .checkFid({
        requestBody: {
          value,
        },
      })
      .then((response) => {
        if (!response.taken) {
          return true;
        }
        return errorMessage;
      })
      .catch(() => errorMessage);
  }, 100) as (value: string) => Promise<boolean | string>;

  return validate;
};
