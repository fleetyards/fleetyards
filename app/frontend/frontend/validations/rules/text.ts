import type { I18nPluginOptions } from "@/shared/plugins/I18n";

const regex =
  /^[\d\w\bÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚàâæçéèêëïîôœùûüÿäöáíñóú[]()-_'".,?!:;\s]*$/i;

export const useRule = (t: I18nPluginOptions["t"]) => {
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
