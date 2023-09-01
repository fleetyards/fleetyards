import { useApiClient } from "@/frontend/composables/useApiClient";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import { debounce } from "ts-debounce";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const { users: usersService } = useApiClient();

  const errorMessage = t("messages.error.usernameTaken");

  const validate = debounce(async (value: string) => {
    return usersService
      .checkUsername({
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
      .catch(() => t("messages.error.usernameTaken"));
  }, 200);

  return validate;
};
