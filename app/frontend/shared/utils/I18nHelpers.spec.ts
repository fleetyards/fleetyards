import { describe, expect, it } from "vitest";
import { I18n } from "i18n-js";
import translations from "@/translations";
import { i18nHelpers } from "./I18nHelpers";

const i18nIn = (locale: string) => {
  const i18n = new I18n({
    [locale]: { datetime: { formats: { date: "d MMMM y" } } },
  });
  i18n.locale = locale;

  return i18n;
};

const hoursAgo = (hours: number) =>
  new Date(Date.now() - hours * 3600_000).toISOString();

describe("i18nHelpers", () => {
  it("writes a relative time in the UI's language", () => {
    expect(i18nHelpers(i18nIn("de")).timeDistance(hoursAgo(72))).toBe(
      "vor 3 Tagen",
    );
    expect(i18nHelpers(i18nIn("fr")).timeDistance(hoursAgo(72))).toBe(
      "il y a 3 jours",
    );
    expect(i18nHelpers(i18nIn("en")).timeDistance(hoursAgo(72))).toBe(
      "3 days ago",
    );
  });

  it("names the month in the UI's language", () => {
    expect(
      i18nHelpers(i18nIn("de")).l(
        "2026-09-29T12:00:00Z",
        "datetime.formats.date",
      ),
    ).toBe("29 September 2026");
    expect(
      i18nHelpers(i18nIn("fr")).lUtc(
        "2026-09-29T12:00:00Z",
        "datetime.formats.date",
      ),
    ).toBe("29 septembre 2026");
  });

  it("follows a locale switch", () => {
    const i18n = i18nIn("en");
    const { timeDistance } = i18nHelpers(i18n);

    i18n.locale = "it";

    expect(timeDistance(hoursAgo(72))).toBe("3 giorni fa");
  });

  it("falls back to English for a locale date-fns is not given", () => {
    expect(i18nHelpers(i18nIn("xx")).timeDistance(hoursAgo(72))).toBe(
      "3 days ago",
    );
  });

  it("writes a UTC timestamp in UTC, whatever the reader's own zone", () => {
    // Ahead of UTC, so 23:30 UTC is already the next day locally: a runner that
    // is itself on UTC would not tell the two apart.
    const zone = process.env.TZ;
    process.env.TZ = "Europe/Berlin";

    try {
      const { lUtc } = i18nHelpers(i18nIn("en"));

      expect(lUtc("2026-09-29T23:30:00Z", "datetime.formats.date")).toBe(
        "29 September 2026",
      );
    } finally {
      process.env.TZ = zone;
    }
  });

  it("writes the default timestamp in the UI's language, connective included", () => {
    const withAppTranslations = (locale: string) => {
      const i18n = new I18n(translations);
      i18n.locale = locale;

      return i18nHelpers(i18n);
    };
    const timestamp = "2026-09-29T12:00:00Z";

    expect(withAppTranslations("de").lUtc(timestamp)).toBe(
      "29. September 2026 um 12:00 UTC",
    );
    expect(withAppTranslations("fr").lUtc(timestamp)).toBe(
      "29 septembre 2026 à 12:00 UTC",
    );
    expect(withAppTranslations("zh-CN").lUtc(timestamp)).toBe(
      "2026 年 9 月 29 日 12:00 UTC",
    );
    expect(withAppTranslations("en").lUtc(timestamp)).toBe(
      "29 September 2026 at 12:00 UTC",
    );
  });
});
