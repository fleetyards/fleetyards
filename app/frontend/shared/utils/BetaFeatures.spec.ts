import { describe, expect, it } from "vitest";
import { FeatureFlagName } from "@/services/fyApi";
import { isBetaFeature } from "./BetaFeatures";

describe("isBetaFeature", () => {
  it("is true for a flag that is still rolling out", () => {
    expect(isBetaFeature(FeatureFlagName.HANGAR_PLANNER)).toBe(true);
  });

  it("is false for a permanent flag", () => {
    expect(isBetaFeature(FeatureFlagName.OAUTH_DISCORD)).toBe(false);
  });

  it("is true for a stack with one beta flag in it", () => {
    expect(
      isBetaFeature([
        FeatureFlagName.OAUTH_DISCORD,
        FeatureFlagName.FLEET_TOURS,
      ]),
    ).toBe(true);
  });

  it("is false without a flag", () => {
    expect(isBetaFeature(undefined)).toBe(false);
    expect(isBetaFeature([])).toBe(false);
  });
});
