import { describe, expect, it } from "vitest";
import {
  type BlueprintCostModifier,
  BlueprintRampEnum,
} from "@/services/fyApi";
import { useQualityRamp } from "./useQualityRamp";

const pips: BlueprintCostModifier[] = [
  [0, 399, -1],
  [400, 899, 0],
  [900, 1000, 1],
].map(([from, to, amount]) => ({
  name: "Power Pips",
  propertyKey: "gpp_itemresource_powergeneration",
  ramp: BlueprintRampEnum.LINEAR_INTEGER_ADDITIVE,
  startQuality: from,
  endQuality: to,
  modifierAtStart: amount,
  modifierAtEnd: amount,
  baseValue: 28,
}));

const rampAt = (quality: number) =>
  useQualityRamp(
    () => pips,
    () => quality,
  ).ramps.value[0];

describe("useQualityRamp", () => {
  it("reads an additive ramp as an amount added to the figure", () => {
    const ramp = rampAt(950);

    expect(ramp.plotted).toBe(true);
    expect(ramp.headline).toBe("29");
    expect(ramp.delta).toBe("+1");
    expect(ramp.factor).toBe("+1");
    expect(ramp.span).toBe("-1 → +1");
    expect(ramp.trend).toBe("better");
  });

  it("adds nothing in the neutral band and takes a step off below it", () => {
    expect(rampAt(500).headline).toBe("28");
    expect(rampAt(500).trend).toBe("level");
    expect(rampAt(100).headline).toBe("27");
    expect(rampAt(100).trend).toBe("worse");
  });
});
