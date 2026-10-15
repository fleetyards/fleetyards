import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { BuybackPledgeKindEnum } from "@/services/fyApi";
import { buybackRsiUrl, rsiHangarUrl } from "./rsiPledgeUrls";

const originalEndpoint = window.RSI_ENDPOINT;

beforeEach(() => {
  window.RSI_ENDPOINT = "https://rsi.test";
});

afterEach(() => {
  window.RSI_ENDPOINT = originalEndpoint;
});

describe("buybackRsiUrl", () => {
  it("links a pledge to its own buy-back page", () => {
    expect(
      buybackRsiUrl({
        kind: BuybackPledgeKindEnum.SHIP,
        rsiPledgeId: "42",
        rsiPage: 3,
      }),
    ).toBe("https://rsi.test/pledge/buyback/42");
  });

  it("links an upgrade to the page of the list it was read from", () => {
    expect(
      buybackRsiUrl({
        kind: BuybackPledgeKindEnum.UPGRADE,
        rsiPledgeId: "7",
        rsiPage: 3,
      }),
    ).toBe("https://rsi.test/account/buy-back-pledges?page=3");
  });

  it("links an upgrade read before pages were kept to the list", () => {
    expect(
      buybackRsiUrl({ kind: BuybackPledgeKindEnum.UPGRADE, rsiPledgeId: "7" }),
    ).toBe("https://rsi.test/account/buy-back-pledges");
  });
});

describe("rsiHangarUrl", () => {
  it("links to the page of the hangar the pledge was read from", () => {
    expect(rsiHangarUrl({ rsiPage: 5 })).toBe(
      "https://rsi.test/account/pledges?page=5",
    );
  });

  it("links to the hangar itself for the first page or none", () => {
    expect(rsiHangarUrl({ rsiPage: 1 })).toBe(
      "https://rsi.test/account/pledges",
    );
    expect(rsiHangarUrl()).toBe("https://rsi.test/account/pledges");
  });
});
