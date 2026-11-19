import { describe, expect, it } from "vitest";
import { FeatureFlagName } from "@/services/fyApi";
import { isBetaFeature } from "./BetaFeatures";

const beta = [FeatureFlagName.HANGAR_PLANNER, FeatureFlagName.FLEET_TOURS];

describe("isBetaFeature", () => {
  it("is true for a flag users or fleets can switch on", () => {
    expect(isBetaFeature(FeatureFlagName.HANGAR_PLANNER, beta)).toBe(true);
  });

  it("is false for a flag nobody can switch on themselves", () => {
    expect(isBetaFeature(FeatureFlagName.STARMAP, beta)).toBe(false);
  });

  it("is true for a stack with one beta flag in it", () => {
    expect(
      isBetaFeature(
        [FeatureFlagName.STARMAP, FeatureFlagName.FLEET_TOURS],
        beta,
      ),
    ).toBe(true);
  });

  it("is false without a flag or before the list is known", () => {
    expect(isBetaFeature(undefined, beta)).toBe(false);
    expect(isBetaFeature(FeatureFlagName.HANGAR_PLANNER, undefined)).toBe(
      false,
    );
  });
});
