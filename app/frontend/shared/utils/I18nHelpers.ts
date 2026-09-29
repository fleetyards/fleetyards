import type { I18n } from "i18n-js";
import { parseISO, formatDistance, type Locale } from "date-fns";
import { format, formatInTimeZone } from "date-fns-tz";
import { de } from "date-fns/locale/de";
import { enUS } from "date-fns/locale/en-US";
import { es } from "date-fns/locale/es";
import { fr } from "date-fns/locale/fr";
import { it } from "date-fns/locale/it";
import { zhCN } from "date-fns/locale/zh-CN";
import { zhTW } from "date-fns/locale/zh-TW";

// date-fns carries each language's own grammar for month names and relative
// times, down to German's "vor 3 Tagen"; without one it writes English.
const DATE_LOCALES: Record<string, Locale> = {
  de,
  en: enUS,
  es,
  fr,
  it,
  "zh-CN": zhCN,
  "zh-TW": zhTW,
};

const formatStat = (i18n: I18n, value: number): string => {
  // Collapse to a single decimal (27.55 -> 27.6) before formatting; trailing
  // zeros are stripped below so whole numbers never show a bare ",00".
  const formatted = i18n.l("number", Math.round(value * 10) / 10);
  const separator = i18n.t("number.format.separator") || ",";
  const delimiter = i18n.t("number.format.delimiter") || ".";

  const [integer, decimal] = formatted.split(separator);
  const stripped = decimal?.replace(/0+$/, "");
  const result = stripped ? `${integer}${separator}${stripped}` : integer;

  // Narrow no-break space as the thousands separator. A hair space (U+200A) was
  // too thin to group six-figure values legibly (288000 read as one run of
  // digits), and being breakable it let values split across lines mid-number.
  return result.replaceAll(delimiter, "\u202F");
};

export const i18nHelpers = (i18n: I18n) => {
  // Read on every call, so a locale switch applies without a reload.
  const dateLocale = () => DATE_LOCALES[i18n.locale] ?? enUS;

  const l = (value: string, dateFormat = "datetime.formats.default") =>
    format(parseISO(value), i18n.t(dateFormat), { locale: dateLocale() });

  // formatInTimeZone, not format with a timeZone option: that one only names
  // the zone and prints the reader's local time under the label "UTC".
  const lUtc = (value: string, dateFormat = "datetime.formats.default") =>
    formatInTimeZone(parseISO(value), "UTC", i18n.t(dateFormat), {
      locale: dateLocale(),
    });

  const timeDistance = (value: string) => {
    return formatDistance(parseISO(value), new Date(), {
      addSuffix: true,
      locale: dateLocale(),
    });
  };

  const toNumber = (value?: number | string | null, units = "") => {
    // Default: round to a single decimal and strip trailing zeros so every stat
    // reads cleanly (750,00 -> 750; 27,55 -> 27,6) while staying precise.
    let count: string | number =
      value != null && value !== "" && Number.isFinite(Number(value))
        ? formatStat(i18n, Number(value))
        : i18n.l("number", value);

    if (units === "weight") {
      count = formatStat(i18n, (value as number) / 1000);
    }

    if (units === "newton") {
      count = i18n.numberToRounded((value as number) / 1000, { precision: 0 });
    }

    if (units === "driveSpeed" || units === "thrust") {
      count = formatStat(i18n, (value as number) / 1000);
    }

    if (units === "cargo" && value) {
      count = value;
    }

    if (units === "people") {
      count = value || 1;
    }

    if (units === "ships") {
      count = value || 1;
    }

    if (units === "speed" && value) {
      count = String(value || "")
        .split(" - ")
        .map((item) => formatStat(i18n, Number(item)))
        .join(" - ");
    }

    if (
      !value ||
      (["speed", "rotation"].includes(units) && Number(value) <= 0)
    ) {
      return i18n.t("labels.notAvailable");
    }

    if (!units) {
      return count;
    }

    return i18n.t(`number.${units}`, { count } as { count: number });
  };

  const toDollar = (value?: number) => {
    if (!value) {
      return "-";
    }

    return i18n.numberToCurrency(value, {
      precision: 2,
      unit: "$",
    });
  };

  const toAu = (value: number | string) => {
    if (!value) {
      return "-";
    }
    return i18n.numberToCurrency(value, {
      precision: 2,
      unit: i18n.t("number.units.au"),
      format: "%n %u",
    });
  };

  const toUEC = (value?: number, unit?: string) => {
    if (!unit) {
      /* tslint:disable:no-parameter-reassignment */

      unit = i18n.t("number.units.uec");
      /* tslint:enable:no-parameter-reassignment */
    }

    if (!value) {
      return "-";
    }

    return i18n.numberToCurrency(value, {
      precision: 2,
      unit,
      format: '%n <span class="text-muted">%u</span>',
    });
  };

  return {
    l,
    lUtc,
    timeDistance,
    toNumber,
    toDollar,
    toAu,
    toUEC,
  };
};
