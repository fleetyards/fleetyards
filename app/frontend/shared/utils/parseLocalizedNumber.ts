const decimalSeparatorFor = (locale: string) =>
  new Intl.NumberFormat(locale)
    .formatToParts(1.1)
    .find((part) => part.type === "decimal")?.value ?? ".";

// A grouped number is one to three digits, then groups of exactly three.
// "12,34,567" is a typo, not a number, and is refused rather than guessed at.
const isGrouped = (text: string, separator: string) =>
  new RegExp(`^-?\\d{1,3}(\\${separator}\\d{3})+$`).test(text);

// Reads a number the way a person in `locale` types it, and answers the
// canonical "1234.5" the API takes, or null. A native number field cannot do
// this: it follows the browser's language rather than the page's, so a German
// page in an English browser drops "1.500,50" entirely.
//
// The locale only breaks a tie. Someone who writes both separators has said
// which is which -- the last one is the decimal -- and a separator repeated is
// grouping in every locale.
export const parseLocalizedNumber = (
  value: unknown,
  locale: string,
): string | null => {
  if (typeof value !== "string" && typeof value !== "number") {
    return null;
  }

  let text = String(value)
    .trim()
    .replace(/[\s  ']/g, "");

  if (!text) {
    return null;
  }

  const hasDot = text.includes(".");
  const hasComma = text.includes(",");

  if (hasDot && hasComma) {
    const decimal = text.lastIndexOf(".") > text.lastIndexOf(",") ? "." : ",";
    const group = decimal === "." ? "," : ".";
    const [whole, fraction, ...rest] = text.split(decimal);

    if (rest.length || !isGrouped(whole, group)) {
      return null;
    }

    text = `${whole.split(group).join("")}.${fraction}`;
  } else if (hasDot || hasComma) {
    const separator = hasDot ? "." : ",";
    const occurrences = text.split(separator).length - 1;
    const digitsAfter = text.length - text.lastIndexOf(separator) - 1;

    if (occurrences > 1) {
      if (!isGrouped(text, separator)) {
        return null;
      }

      text = text.split(separator).join("");
    } else if (
      separator !== decimalSeparatorFor(locale) &&
      digitsAfter === 3 &&
      isGrouped(text, separator)
    ) {
      text = text.replace(separator, "");
    } else {
      text = text.replace(separator, ".");
    }
  }

  if (!/^-?\d+(\.\d+)?$/.test(text)) {
    return null;
  }

  return text;
};
