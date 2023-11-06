import { useApiClient } from "@/frontend/composables/useApiClient";
import { debounce } from "ts-debounce";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const { vehicles: vehiclesService } = useApiClient();

  const errorMessage = t("messages.error.serialTaken");

  const validate = debounce(async (value: string) => {
    return vehiclesService
      .vehicleCheckSerial({
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
