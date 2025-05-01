import { useI18n } from "@/shared/composables/useI18n";

const regex =
  /^[\d\w\bÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚàâæçéèêëïîôœùûüÿäöáíñóú[]()-_'".,?!:;\s]*$/i;

export const useRule = () => {
  const { t } = useI18n();

  const validateText = (
    value: string,
    [_target]: [unknown],
    ctx: FieldValidationMetaInfo,
  ) => {
    if (regex.test(value)) {
      return true;
    }

    return t("messages.error.textInvalid", { field: ctx.field });
  };

  return validateText;
};
