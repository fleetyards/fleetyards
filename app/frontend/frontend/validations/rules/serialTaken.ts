import { checkSerialVehicle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export const useRule = () => {
  const { t } = useI18n();

  const errorMessage = t("messages.error.serialTaken");

  const validate = async (value: string) =>
    checkSerialVehicle({
      value,
    })
      .then((response) => (response.taken ? errorMessage : true))
      .catch(() => errorMessage);

  return validate;
};
