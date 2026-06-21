// Convert a decimal amount string/number ("12.34") into integer cents.
// Avoids the IEEE-754 trap where `Math.round(2.675 * 100)` returns 267 —
// we operate on the integer + fractional parts of the string directly so
// no float multiplication is involved.
export const toCents = (value: number | string | undefined | null): number => {
  if (value === undefined || value === null || value === "") return 0;

  const str = String(value).trim().replace(",", ".");
  const negative = str.startsWith("-");
  const unsigned = negative ? str.slice(1) : str;

  const [intPart, fracPart = ""] = unsigned.split(".");
  const fracPadded = (fracPart + "00").slice(0, 2);

  const cents = Number(intPart || "0") * 100 + Number(fracPadded || "0");

  return negative ? -cents : cents;
};
