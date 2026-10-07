export type RSIBuybackDetail = {
  price: number;
  currency: string;
  insuranceMonths?: number;
  lifetimeInsurance: boolean;
};

const MONTHS_INSURANCE = /^(\d+)\s+Months?\s+Insurance$/i;

const LIFETIME_INSURANCE = /^Lifetime\s+Insurance$/i;

// The buy-back page of one pledge (`/pledge/buyback/<id>`). `undefined` when the
// HTML has no price on it: a login redirect, an error page, or a pledge that is
// gone. The price is what RSI charges this account, in the currency the
// account shows prices in, tax included.
export const extractBuybackDetail = (
  html: string,
): RSIBuybackDetail | undefined => {
  const htmlDoc = new DOMParser().parseFromString(html, "text/html");

  const finalPrice = htmlDoc.querySelector<HTMLElement>("strong.final-price");
  const cents = Number.parseInt(finalPrice?.dataset.value || "", 10);
  const currency = finalPrice?.dataset.currency?.trim().toUpperCase();

  if (Number.isNaN(cents) || !currency || !/^[A-Z]{3}$/.test(currency)) {
    return undefined;
  }

  const items = Array.from(
    htmlDoc.querySelectorAll(".package-listing.item li"),
  ).map((item) => item.textContent?.trim().replace(/\s+/g, " ") || "");

  const lifetimeInsurance = items.some((item) => LIFETIME_INSURANCE.test(item));

  // A package of several ships lists one insurance per ship; the longest is
  // the one worth naming.
  const months = items
    .map((item) => Number.parseInt(item.match(MONTHS_INSURANCE)?.[1] || "", 10))
    .filter((value) => !Number.isNaN(value));

  return {
    price: cents / 100,
    currency,
    insuranceMonths:
      lifetimeInsurance || months.length === 0
        ? undefined
        : Math.max(...months),
    lifetimeInsurance,
  };
};
