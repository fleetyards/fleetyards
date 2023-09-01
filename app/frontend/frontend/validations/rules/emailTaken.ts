import { useApiClient } from "@/frontend/composables/useApiClient";
import { debounce } from "ts-debounce";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const { users: usersService } = useApiClient();

  const errorMessage = t("messages.error.emailTaken");

  const validate = debounce(async (value: string) => {
    return usersService
      .checkEmail({
        requestBody: {
          value,
        },
      })
      .then((response) => {
        if (response.taken) {
          return true;
        }
        return errorMessage;
      })
      .catch(() => errorMessage);
  }, 200);

  return validate;
};
