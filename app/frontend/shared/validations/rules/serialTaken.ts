import { useFyApiClient } from "@/shared/composables/useFyApiClient";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (
  t: I18nPluginOptions["t"],
  currentLocale: I18nPluginOptions["currentLocale"],
) => {
  const { vehicles: vehiclesService } = useFyApiClient(currentLocale);

  const errorMessage = t("messages.error.serialTaken");

  const validate = (value: string) => {
    return vehiclesService
      .vehicleCheckSerial({
        requestBody: {
          serial: value,
        },
      })
      .then((response) => {
        if (!response.serialTaken) {
          return true;
        }
        return errorMessage;
      })
      .catch(() => errorMessage);
  };

  return validate;
};
