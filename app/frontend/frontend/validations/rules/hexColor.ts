import { useI18n } from "@/shared/composables/useI18n";

const regex = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/;

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.colorInvalid");

  const validateText = (value: string) => {
    if (regex.test(value)) {
      return true;
    }

    return errorMessage;
  };

  return validateText;
};
