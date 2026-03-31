import { checkUsername } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.userNotFound");

  const validate = async (value: string) =>
    checkUsername({
      value,
    })
      .then((response) => (response.taken ? true : errorMessage))
      .catch(() => errorMessage);

  return validate;
};
