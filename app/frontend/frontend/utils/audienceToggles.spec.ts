import { describe, expect, it } from "vitest";
import { narrowerAudienceDisabled } from "./audienceToggles";

describe("narrowerAudienceDisabled", () => {
  it("locks the narrower switch while the surface is public", () => {
    expect(narrowerAudienceDisabled(true, false)).toBe(true);
  });

  it("leaves it open when the surface is not public", () => {
    expect(narrowerAudienceDisabled(false, false)).toBe(false);
  });

  // A surface with no public twin at all -- a fleet's roster -- is never locked
  // by this, because there is nothing for public to win over.
  it("leaves it open when there is no public value", () => {
    expect(narrowerAudienceDisabled(undefined, false)).toBe(false);
    expect(narrowerAudienceDisabled(null, false)).toBe(false);
  });

  it("locks everything while the form is saving", () => {
    expect(narrowerAudienceDisabled(false, true)).toBe(true);
    expect(narrowerAudienceDisabled(true, true)).toBe(true);
  });
});
