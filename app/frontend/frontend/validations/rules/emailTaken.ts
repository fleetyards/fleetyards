import { checkEmail } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.emailTaken");

  const validate = async (value: string) =>
    checkEmail({
      value,
    })
      .then((response) => {
        return response.taken ? true : errorMessage;
      })
      .catch(() => {
        return errorMessage;
      });

  return validate;
};
