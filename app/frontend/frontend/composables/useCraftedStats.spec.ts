import { describe, expect, it } from "vitest";
import { type BlueprintCostSlot } from "@/services/fyApi";
import { useCraftedStats } from "./useCraftedStats";

const modifier = (attrs = {}) => ({
  name: "Max. Shield Strength",
  propertyKey: "gpp_shield_maxhealth",
  ramp: "linear",
  startQuality: 0,
  endQuality: 1000,
  modifierAtStart: 0.8,
  modifierAtEnd: 1.2,
  baseValue: 100000,
  unit: null,
  ...attrs,
});

const slot = (position: number, modifiers: object[]) =>
  ({ position, options: [], modifiers }) as unknown as BlueprintCostSlot;

const statsFor = (slots: BlueprintCostSlot[], at: Record<number, number>) =>
  useCraftedStats(
    () => slots,
    (position) => at[position] ?? 500,
  ).stats.value;

describe("useCraftedStats", () => {
  it("applies the factor to the catalogue's own figure", () => {
    const [stat] = statsFor([slot(0, [modifier()])], { 0: 1000 });

    expect(stat.value).toBe("120,000");
    expect(stat.base).toBe("100,000");
  });

  it("lands on the catalogue figure at the neutral grade", () => {
    const [stat] = statsFor([slot(0, [modifier()])], { 0: 500 });

    expect(stat.value).toBe("100,000");
  });

  // 358 of the recipes move one stat from two slots, and neither slot's own
  // panel can state the result.
  it("composes the factors of two slots moving one stat", () => {
    const [stat] = statsFor([slot(0, [modifier()]), slot(1, [modifier()])], {
      0: 1000,
      1: 1000,
    });

    expect(stat.slots).toBe(2);
    expect(stat.factor).toBe("1.440×");
    expect(stat.value).toBe("144,000");
  });

  it("keeps each slot's own grade when they differ", () => {
    const [stat] = statsFor([slot(0, [modifier()]), slot(1, [modifier()])], {
      0: 0,
      1: 1000,
    });

    expect(stat.factor).toBe("0.960×");
  });

  // 2,060 modifiers move a stat the catalogue holds no figure for.
  it("falls back to the factor with no figure to multiply", () => {
    const [stat] = statsFor([slot(0, [modifier({ baseValue: null })])], {
      0: 1000,
    });

    expect(stat.value).toBe("1.200×");
    expect(stat.base).toBeUndefined();
  });

  // 598 modifiers name a stat and carry no figures at all.
  it("leaves out a stat with no figures", () => {
    const stats = statsFor(
      [slot(0, [modifier({ modifierAtStart: null, modifierAtEnd: null })])],
      {},
    );

    expect(stats).toHaveLength(0);
  });

  it("carries the unit into the result", () => {
    const [stat] = statsFor(
      [slot(0, [modifier({ baseValue: 50, unit: "%" })])],
      { 0: 1000 },
    );

    expect(stat.value).toBe("60%");
  });
});
