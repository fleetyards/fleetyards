import { useI18n } from "@/shared/composables/useI18n";
import { gameSerial } from "@/frontend/utils/vehicleSegment";

export const useRule = () => {
  const { t } = useI18n();

  const validate = (
    value: string | null | undefined,
    [_target]: [unknown],
    ctx: FieldValidationMetaInfo,
  ) => {
    if (!value || gameSerial(value)) {
      return true;
    }

    return t("messages.error.vehicleSerialInvalid", { field: ctx.field });
  };

  return validate;
};
