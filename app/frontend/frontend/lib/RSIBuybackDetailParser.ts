// `cents` is the page's price in `currency`, the account's currency with tax as
// RSI applies it; see `toUsdCents` for RSI's own USD figure.
export type RSIBuybackDetail = {
  cents?: number;
  currency?: string;
  insuranceMonths?: number;
  lifetimeInsurance: boolean;
  shipNames?: string[];
};

const MONTHS_INSURANCE = /^(\d+)\s+Months?\s+Insurance$/i;

const LIFETIME_INSURANCE = /^Lifetime\s+Insurance$/i;

// "ship: Shiv Manufacturer: Grey's Market Focus: Heavy Fighter"
const SHIP_NAME = /^(?:ship:\s*)?(.+?)(?:\s*Manufacturer:.*)?$/i;

// The buy-back page of one pledge (`/pledge/buyback/<id>`). `undefined` when the
// HTML is not a pledge page at all, such as a login redirect or an error page.
// A pledge page without a readable price still answers, with its insurance, so
// that pledge is not asked about on every sync.
export const extractBuybackDetail = (
  html: string,
): RSIBuybackDetail | undefined => {
  const htmlDoc = new DOMParser().parseFromString(html, "text/html");

  const finalPrice = htmlDoc.querySelector<HTMLElement>("strong.final-price");

  if (!finalPrice && !htmlDoc.querySelector(".package-listing")) {
    return undefined;
  }

  const cents = Number.parseInt(finalPrice?.dataset.value || "", 10);
  const currency = finalPrice?.dataset.currency?.trim().toUpperCase();
  const priced =
    !Number.isNaN(cents) && !!currency && /^[A-Z]{3}$/.test(currency);

  const items = Array.from(
    htmlDoc.querySelectorAll(".package-listing.item li"),
  ).map((item) => item.textContent?.trim().replace(/\s+/g, " ") || "");

  // Without the listing a pack's ships are unknown, not none, so it is read
  // again on the next sync rather than stored as holding no ship.
  const shipListing = htmlDoc.querySelector(".package-listing.ship");
  const shipNames = Array.from(shipListing?.querySelectorAll("li") ?? [])
    .map((ship) => {
      const text = ship.textContent?.trim().replace(/\s+/g, " ") || "";

      return text.match(SHIP_NAME)?.[1]?.trim() || "";
    })
    .filter((name) => name.length > 0);

  const lifetimeInsurance = items.some((item) => LIFETIME_INSURANCE.test(item));

  // A package of several ships lists one insurance per ship; the longest is
  // the one worth naming.
  const months = items
    .map((item) => Number.parseInt(item.match(MONTHS_INSURANCE)?.[1] || "", 10))
    .filter((value) => !Number.isNaN(value));

  return {
    ...(priced ? { cents, currency } : {}),
    insuranceMonths:
      lifetimeInsurance || months.length === 0
        ? undefined
        : Math.max(...months),
    lifetimeInsurance,
    ...(shipListing ? { shipNames } : {}),
  };
};
