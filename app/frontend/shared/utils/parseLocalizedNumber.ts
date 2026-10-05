const decimalSeparatorFor = (locale: string) =>
  new Intl.NumberFormat(locale)
    .formatToParts(1.1)
    .find((part) => part.type === "decimal")?.value ?? ".";

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

    text = text.split(group).join("").replace(decimal, ".");
  } else if (hasDot || hasComma) {
    const separator = hasDot ? "." : ",";
    const occurrences = text.split(separator).length - 1;
    const digitsAfter = text.length - text.lastIndexOf(separator) - 1;

    const isGrouping =
      occurrences > 1 ||
      (separator !== decimalSeparatorFor(locale) && digitsAfter === 3);

    text = isGrouping
      ? text.split(separator).join("")
      : text.replace(separator, ".");
  }

  if (!/^-?\d+(\.\d+)?$/.test(text)) {
    return null;
  }

  return text;
};
