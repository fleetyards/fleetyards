import { describe, it, expect } from "vitest";
import { toUsdCents } from "./RSIStorePricing";

const euro = {
  currencyCode: "EUR",
  exchangeRate: 8800,
  taxRate: 1900,
  isTaxInclusive: true,
};

describe("toUsdCents", () => {
  // Read from one account's buy-back pages, with the USD prices they were
  // pledged for.
  it.each([
    [15708, 15000],
    [9425, 9000],
    [4189, 4000],
    [10472, 10000],
    [3665, 3500],
    [99484, 95000],
  ])("turns %i euro cents back into %i dollar cents", (cents, usd) => {
    expect(toUsdCents(cents, "EUR", euro)).toBe(usd);
  });

  it("keeps a USD price as it is", () => {
    expect(
      toUsdCents(15000, "USD", {
        currencyCode: "USD",
        exchangeRate: 10000,
        taxRate: 0,
        isTaxInclusive: false,
      }),
    ).toBe(15000);
  });

  it("converts nothing priced in another currency than the pricing", () => {
    expect(toUsdCents(15708, "GBP", euro)).toBeUndefined();
  });

  // What RSI answers without a store token.
  it("converts nothing with an unscaled rate", () => {
    expect(
      toUsdCents(15708, "EUR", { ...euro, exchangeRate: 1, taxRate: 0 }),
    ).toBeUndefined();
  });
});
