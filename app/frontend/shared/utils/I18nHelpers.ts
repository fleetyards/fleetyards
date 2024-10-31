import type { I18n } from "i18n-js";
import { parseISO, formatDistance } from "date-fns";
import { format } from "date-fns-tz";

export const i18nHelpers = (i18n: I18n) => {
  const l = (value: string, dateFormat = "datetime.formats.default") =>
    format(parseISO(value), i18n.t(dateFormat));

  const lUtc = (value: string, dateFormat = "datetime.formats.default") =>
    format(parseISO(value), i18n.t(dateFormat), { timeZone: "UTC" });

  const timeDistance = (value: string) => {
    return formatDistance(parseISO(value), new Date(), {
      addSuffix: true,
    });
  };

  const toNumber = (value?: number | string | null, units = "") => {
    let count: string | number = i18n.l("number", value);

    if (units === "weight") {
      count = i18n.l("number", (value as number) / 1000);
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
        .map((item) => i18n.l("number", item))
        .join(" - ");
    }

    if (
      !value ||
      (["speed", "rotation"].includes(units) && Number(value) <= 0)
    ) {
      return i18n.t("labels.notAvailable");
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
      // eslint-disable-next-line no-param-reassign
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
