import { checkFID } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.fleetTaken");

  const validate = async (value: string) =>
    checkFID({
      value,
    })
      .then((response) => (response.taken ? errorMessage : true))
      .catch(() => errorMessage);

  return validate;
};
