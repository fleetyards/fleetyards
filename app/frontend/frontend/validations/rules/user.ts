import { useApiClient } from "@/frontend/composables/useApiClient";

import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (t: I18nPluginOptions["t"]) => {
  const { users: usersService } = useApiClient();

  const errorMessage = t("messages.error.userNotFound");

  const validate = (value: string) => {
    // TODO: API_SCHEMA - needs checkUsername api endpoint
    return usersService
      .checkUsername({
        username: value,
      })
      .then((response) => {
        if (response.usernameTaken) {
          return true;
        }
        return errorMessage;
      })
      .catch(() => errorMessage);
  };

  return validate;
};
