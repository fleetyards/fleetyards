import { afterEach, describe, expect, it } from "vitest";
import { shortUrl } from "./shortUrl";

describe("shortUrl", () => {
  afterEach(() => {
    window.SHORT_DOMAIN = "";
  });

  it("builds a link on the short domain", () => {
    window.SHORT_DOMAIN = "fltyrd.net";

    expect(shortUrl("/f/FY/ships", "?fleetchart=true")).toBe(
      `${window.location.protocol}//fltyrd.net/f/FY/ships?fleetchart=true`,
    );
  });

  it("returns nothing without a short domain", () => {
    window.SHORT_DOMAIN = "";

    expect(shortUrl("/f/FY/ships")).toBeUndefined();
  });
});
