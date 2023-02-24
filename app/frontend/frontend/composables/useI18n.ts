import I18n from "i18n-js";
import { parseISO } from "date-fns";
import { format } from "date-fns-tz";
import en from "@/translations/en";
import de from "@/translations/de";

const availableLocales = ["en", "de"];
I18n.defaultLocale = "en";
I18n.locale = "en";
I18n.fallbacks = true;
I18n.translations.en = en;
I18n.translations.de = de;

type I18nTranslateOptions = {
  [key: string]: I18nTranslateOptions | string;
};

const t = (key: string, options?: I18nTranslateOptions) => I18n.t(key, options);

const l = (value: string, dateFormat = "datetime.formats.default") =>
  format(parseISO(value), I18n.t(dateFormat));

const toNumber = (value: number | string, units: string) => {
  let count: string | number = I18n.l("number", value);
  if (units === "weight") {
    count = I18n.l("number", (value as number) / 1000);
  }
  if (units === "people") {
    count = value;
  }
  if (units === "speed" && value) {
    count = (value as string)
      .split(" - ")
      .map((item) => I18n.l("number", item))
      .join(" - ");
  }
  if (!value || (["speed", "rotation"].includes(units) && value <= 0)) {
    return I18n.t("labels.not-available");
  }
  return I18n.t(`number.${units}`, {
    count,
  });
};

const toDollar = (value: number) =>
  I18n.toCurrency(value, {
    precision: 2,
    unit: "$",
  });

const toAu = (value: number) => {
  if (!value) {
    return "-";
  }
  return I18n.toCurrency(value, {
    precision: 2,
    unit: I18n.t("labels.au"),
    format: "%n %u",
  });
};

const toUEC = (value: number, unit: string) => {
  if (!unit) {
    /* tslint:disable:no-parameter-reassignment */
    // eslint-disable-next-line no-param-reassign
    unit = I18n.t("labels.uec");
    /* tslint:enable:no-parameter-reassignment */
  }

  if (!value) {
    return "-";
  }

  return I18n.toCurrency(value, {
    precision: 2,
    unit,
    format: '%n <span class="text-muted">%u</span>',
  });
};

export default function useI18n() {
  return {
    I18n,
    availableLocales,
    t,
    l,
    toNumber,
    toDollar,
    toAu,
    toUEC,
  };
}
