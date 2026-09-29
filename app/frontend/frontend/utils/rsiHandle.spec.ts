import { describe, expect, it } from "vitest";
import { handleVerifiedViaProfile } from "./rsiHandle";

describe("handleVerifiedViaProfile", () => {
  it("is true only for a handle proved through the RSI bio", () => {
    expect(
      handleVerifiedViaProfile({ rsiHandleVerifiedVia: "rsi_profile" }),
    ).toBe(true);
    expect(
      handleVerifiedViaProfile({ rsiHandleVerifiedVia: "citizenid" }),
    ).toBe(false);
    expect(handleVerifiedViaProfile({})).toBe(false);
  });
});
