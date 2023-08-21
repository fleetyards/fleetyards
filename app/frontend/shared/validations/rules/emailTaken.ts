import { useFyApiClient } from "@/shared/composables/useFyApiClient";

import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useRule = (
  t: I18nPluginOptions["t"],
  currentLocale: I18nPluginOptions["currentLocale"]
) => {
  const { users: usersService } = useFyApiClient(currentLocale);

  const errorMessage = t("messages.error.emailTaken");

  const validate = (value: string) => {
    // TODO: API_SCHEMA - needs checkEmail api endpoint
    return usersService
      .checkEmail({
        email: value,
      })
      .then((response) => {
        if (response.emailTaken) {
          return true;
        }
        return errorMessage;
      })
      .catch(() => errorMessage);
  };

  return validate;
};
