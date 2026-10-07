import { describe, it, expect } from "vitest";
import { extractBuybackDetail } from "./RSIBuybackDetailParser";

// Trimmed from a live `/pledge/buyback/<id>` page.
const detailPage = (items: string[], price = "15708", currency = "EUR") => `
<div class="wcontent clearfix">
  <div class="lcol">
    <div class="price ">
      <strong class="final-price" data-value="${price}" data-currency="${currency}">€157<span class='super'>.08 <span class='currency'>${currency}</span></span></strong>
    </div>
  </div>
  <div class="rcol">
    <div class="package-listing ship">
      <h4>ship in this pack:</h4>
      <ul><li>ship: Shiv Manufacturer: Grey's Market Focus: Heavy Fighter</li></ul>
    </div>
    <div class="package-listing item">
      <h4>Also Contains</h4>
      <ul>${items.map((item) => `<li class="trans-02s">${item}</li>`).join("")}</ul>
    </div>
  </div>
</div>`;

describe("extractBuybackDetail", () => {
  it("reads the price and a term insurance", () => {
    expect(
      extractBuybackDetail(
        detailPage(["6 Month Insurance", "VFG Industrial Hangar"]),
      ),
    ).toEqual({
      price: 157.08,
      currency: "EUR",
      insuranceMonths: 6,
      lifetimeInsurance: false,
    });
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
      price: 10.47,
      currency: "EUR",
      insuranceMonths: undefined,
      lifetimeInsurance: false,
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
    ).toEqual({ insuranceMonths: 6, lifetimeInsurance: false });
  });
});
