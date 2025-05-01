import { checkUsername } from "@/services/fyApi";
import { debounce } from "ts-debounce";
import { useI18n } from "@/shared/composables/useI18n";

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.usernameTaken");

  const validate = debounce(async (value: string) => {
    try {
      const response = await checkUsername({
        value,
      });

      if (response.taken) {
        return errorMessage;
      }

      return true;
    } catch (error) {
      return errorMessage;
    }
  }, 100);

  return validate;
};
