import { useI18n } from "@/shared/composables/useI18n";

const regex = /^[a-zA-Z0-9\-_. ]*$/;

export const useRule = () => {
  const { t } = useI18n();

  const validate = (
    value: string,
    [_target]: [unknown],
    ctx: FieldValidationMetaInfo,
  ) => {
    if (regex.test(value)) {
      return true;
    }

    return t("messages.error.fleetNameInvalid", { field: ctx.field });
  };

  return validate;
};
