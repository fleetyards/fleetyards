import I18n from "i18n-js";
import { parseISO } from "date-fns";
import { format } from "date-fns-tz";
import en from "@/docs/translations/en";

const availableLocales = ["en"];
I18n.defaultLocale = "en";
I18n.locale = "en";
I18n.fallbacks = true;
I18n.translations.en = en;

type I18nTranslateOptions = {
  [key: string]: I18nTranslateOptions | string;
};

const t = (key: string, options?: I18nTranslateOptions) => I18n.t(key, options);

const l = (value: string, dateFormat = "datetime.formats.default") =>
  format(parseISO(value), I18n.t(dateFormat));

export const useI18n = () => ({
  I18n,
  availableLocales,
  t,
  l,
});
