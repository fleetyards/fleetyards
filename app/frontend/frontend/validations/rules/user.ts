import { useApiClient } from "@/frontend/composables/useApiClient";

import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const { users: usersService } = useApiClient();

  const errorMessage = t("messages.error.userNotFound");

  const validate = (value: string) => {
    // TODO: API_SCHEMA - needs checkUsername api endpoint
    return usersService
      .checkUsername({
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
  };

  return validate;
};
