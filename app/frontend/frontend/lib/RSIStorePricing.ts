// How RSI converts the account's prices, as its store answers it: `exchangeRate`
// and `taxRate` in ten-thousandths, so 8800 is 0.88 and 1900 is 19 %.
export type RSIStorePricing = {
  currencyCode: string;
  exchangeRate: number;
  taxRate: number;
  isTaxInclusive: boolean;
};

const RATE_SCALE = 10000;

// RSI converts from USD and rounds to the cent, so dividing back and rounding
// recovers its USD figure exactly whenever the rate is above one, and to the
// cent otherwise.
export const toUsdCents = (
  cents: number,
  currency: string,
  pricing: RSIStorePricing,
): number | undefined => {
  if (currency !== pricing.currencyCode) {
    return undefined;
  }

  if (currency === "USD" && !pricing.isTaxInclusive) {
    return cents;
  }

  // An unscaled rate (RSI answers 1 with no store token) would read a euro
  // price as dollars.
  if (pricing.exchangeRate < RATE_SCALE / 100) {
    return undefined;
  }

  const tax = pricing.isTaxInclusive ? 1 + pricing.taxRate / RATE_SCALE : 1;

  return Math.round(cents / ((pricing.exchangeRate / RATE_SCALE) * tax));
};
