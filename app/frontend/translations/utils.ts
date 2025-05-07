import merge from "lodash.merge";

export type MessagesJSON = {
  en?: unknown;
  de?: unknown;
  es?: unknown;
  fr?: unknown;
  it?: unknown;
  "zh-CN"?: unknown;
  "zh-TW"?: unknown;
};

export const extractTranslations = (
  locale: keyof MessagesJSON,
  files: Record<string, Record<string, MessagesJSON>>,
  additionalTranslations: [MessagesJSON] = [{}],
) => {
  return [
    ...Object.values(files).map((r) => r.default),
    ...additionalTranslations,
  ].reduce((acc, m) => merge(acc, m[locale]), {});
};
