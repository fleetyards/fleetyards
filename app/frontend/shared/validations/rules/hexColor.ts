import type { I18nPluginOptions } from "@/shared/plugins/I18n";

const regex = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/;

export const useRule = (t: I18nPluginOptions["t"]) => {
  const validateText = (value: string) => {
    if (regex.test(value)) {
      return true;
    }

    return t("messages.error.colorInvalid");
  };

  return validateText;
};
