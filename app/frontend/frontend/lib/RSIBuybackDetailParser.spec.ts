import { describe, it, expect } from "vitest";
import { extractBuybackDetail } from "./RSIBuybackDetailParser";

const shivListing =
  "ship: Shiv Manufacturer: Grey's Market Focus: Heavy Fighter";

// Trimmed from a live `/pledge/buyback/<id>` page.
const detailPage = (
  items: string[],
  price = "15708",
  currency = "EUR",
  ships = [shivListing],
) => `
<div class="wcontent clearfix">
  <div class="lcol">
    <div class="price ">
      <strong class="final-price" data-value="${price}" data-currency="${currency}">€157<span class='super'>.08 <span class='currency'>${currency}</span></span></strong>
    </div>
  </div>
  <div class="rcol">
    <div class="package-listing ship">
      <h4>ship in this pack:</h4>
      <ul>${ships.map((ship) => `<li>${ship}</li>`).join("")}</ul>
    </div>
    <div class="package-listing item">
      <h4>Also Contains</h4>
      <ul>${items.map((item) => `<li class="trans-02s">${item}</li>`).join("")}</ul>
    </div>
  </div>
</div>`;

describe("extractBuybackDetail", () => {
  it("reads the price in the account's currency and a term insurance", () => {
    expect(
      extractBuybackDetail(
        detailPage(["6 Month Insurance", "VFG Industrial Hangar"]),
      ),
    ).toEqual({
      cents: 15708,
      currency: "EUR",
      insuranceMonths: 6,
      lifetimeInsurance: false,
      shipNames: ["Shiv"],
    });
  });

  it("names every ship of a pack", () => {
    expect(
      extractBuybackDetail(
        detailPage(["6 Month Insurance"], "15708", "EUR", [
          "ship: Pulse Manufacturer: Mirai Focus: Combat",
          "ship:\n  Freelancer\n  Manufacturer: MISC Focus: Light Freight",
        ]),
      ),
    ).toMatchObject({ shipNames: ["Pulse", "Freelancer"] });
  });

  it("names no ship for a pledge without one", () => {
    expect(
      extractBuybackDetail(
        detailPage(["Sabre - Beyond Paint"], "1047", "EUR", []),
      ),
    ).toMatchObject({ shipNames: [] });
  });

  it("leaves the ships unknown on a page without a ship listing", () => {
    expect(
      extractBuybackDetail(
        '<strong class="final-price" data-value="1047" data-currency="EUR"></strong>',
      ),
    ).not.toHaveProperty("shipNames");
  });

  it("reads lifetime insurance", () => {
    expect(
      extractBuybackDetail(
        detailPage([
          "Cutter - Groundswell Paint",
          "Lifetime Insurance",
          "Self-Land Hangar",
        ]),
      ),
    ).toMatchObject({ insuranceMonths: undefined, lifetimeInsurance: true });
  });

  it("names the longest of several insurances", () => {
    expect(
      extractBuybackDetail(
        detailPage(["6 Month Insurance", "120 Month Insurance"]),
      ),
    ).toMatchObject({ insuranceMonths: 120 });
  });

  it("reads a pledge with no insurance", () => {
    expect(
      extractBuybackDetail(detailPage(["Sabre - Beyond Paint"], "1047")),
    ).toEqual({
      cents: 1047,
      currency: "EUR",
      insuranceMonths: undefined,
      lifetimeInsurance: false,
      shipNames: ["Shiv"],
    });
  });

  it("does not read a page without a price", () => {
    expect(
      extractBuybackDetail(
        "<html><body><form id='sign-in'></form></body></html>",
      ),
    ).toBeUndefined();
  });

  it("reads the insurance of a pledge page without a readable price", () => {
    expect(
      extractBuybackDetail(detailPage(["6 Month Insurance"], "15708", "")),
    ).toEqual({
      insuranceMonths: 6,
      lifetimeInsurance: false,
      shipNames: ["Shiv"],
    });
  });
});
