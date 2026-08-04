import { describe, expect, it } from "vitest";
import { powerPlantPips, type PowerPlantContext } from "./powerPlant";

describe("powerPlantPips", () => {
  it("splits a two-identical-plant ship evenly and sums to the total (Guardian QI)", () => {
    // 2x size-1 plants, powerBase 16 → category total 18 pips.
    const context: PowerPlantContext = { count: 2, sizeSum: 2 };
    const perPlant = powerPlantPips(16, 1, context);

    expect(perPlant).toBe(9);
    expect(perPlant * context.count).toBe(18);
  });

  it("returns the full total for a single-plant ship", () => {
    const context: PowerPlantContext = { count: 1, sizeSum: 3 };

    // n = 1 → round(powerBase/1) + 0
    expect(powerPlantPips(14, 3, context)).toBe(14);
  });

  it("yields integer shares that sum to the category total for four plants", () => {
    // 4x size-2 plants, powerBase 30.
    const n = 4;
    const size = 2;
    const powerBase = 30;
    const context: PowerPlantContext = { count: n, sizeSum: n * size };

    const perPlant = powerPlantPips(powerBase, size, context);
    const total = n * Math.round(powerBase / n) + (n - 1) * context.sizeSum;

    expect(Number.isInteger(perPlant)).toBe(true);
    expect(perPlant * n).toBe(total);
  });

  it("weights mixed plants by size while summing to the total", () => {
    // A size-1 (powerBase 10) and a size-2 (powerBase 20) plant.
    const context: PowerPlantContext = { count: 2, sizeSum: 3 };
    const small = powerPlantPips(10, 1, context);
    const large = powerPlantPips(20, 2, context);

    // per-plant: round(base/2) + (2-1)*size
    expect(small).toBe(Math.round(10 / 2) + 1); // 6
    expect(large).toBe(Math.round(20 / 2) + 2); // 12

    const total =
      Math.round(10 / 2) + Math.round(20 / 2) + (2 - 1) * context.sizeSum;
    expect(small + large).toBe(total);
  });
});
