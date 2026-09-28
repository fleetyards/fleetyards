import { describe, expect, it } from "vitest";
import { fidAtRisk } from "./rsiSid";

describe("fidAtRisk", () => {
  it("flags an SID-shaped fleet ID on an unverified fleet", () => {
    expect(fidAtRisk({ fid: "test", rsiSid: "TEST", rsiVerified: false })).toBe(
      true,
    );
  });

  it("clears once the fleet is verified for that SID", () => {
    expect(fidAtRisk({ fid: "test", rsiSid: "TEST", rsiVerified: true })).toBe(
      false,
    );
  });

  it("still flags a fleet verified for a different SID", () => {
    expect(fidAtRisk({ fid: "TEST", rsiSid: "OTHER", rsiVerified: true })).toBe(
      true,
    );
  });

  it("ignores a fleet ID no SID can match", () => {
    expect(fidAtRisk({ fid: "test-fleet", rsiVerified: false })).toBe(false);
    expect(fidAtRisk({ fid: "ELEVENCHARS", rsiVerified: false })).toBe(false);
  });
});
