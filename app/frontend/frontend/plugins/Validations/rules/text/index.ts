import { I18n } from "@/frontend/lib/I18n";

const regex =
  /^[\d\w\bÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚàâæçéèêëïîôœùûüÿäöáíñóú\[\]\(\)-_'".,?!:;\s]*$/i; // eslint-disable-line no-useless-escape

const validate = (value: string): boolean => regex.test(value);

export { validate };

export default {
  message(field: string) {
    return I18n.t("messages.error.textInvalid", { field });
  },
  validate,
};
