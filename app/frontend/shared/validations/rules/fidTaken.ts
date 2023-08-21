import { useFyApiClient } from "@/shared/composables/useFyApiClient";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (
  t: I18nPluginOptions["t"],
  currentLocale: I18nPluginOptions["currentLocale"]
) => {
  const { fleets: fleetsService } = useFyApiClient(currentLocale);

  const errorMessage = t("messages.error.fleetTaken");

  const validate = (value: string) => {
    return fleetsService
      .checkFid({
        requestBody: {
          fid: value,
        },
      })
      .then((response) => {
        if (!response.taken) {
          return true;
        }
        return errorMessage;
      })
      .catch(() => errorMessage);
  };

  return validate;
};
