import { checkUsername } from "@/services/fyApi";
import { debounce } from "ts-debounce";
import { useI18n } from "@/shared/composables/useI18n";

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.userNotFound");

  const validate = debounce(async (value: string) => {
    try {
      const response = await checkUsername({
        value,
      });

      if (response.taken) {
        return true;
      }

      return errorMessage;
    } catch (error) {
      return errorMessage;
    }
  }, 100);

  return validate;
};
