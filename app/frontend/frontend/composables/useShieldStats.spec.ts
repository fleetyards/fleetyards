import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentShield,
} from "@/services/fyApi";
import { computeShieldStats } from "./useShieldStats";

function shieldHardpoint(typeData: ComponentShield): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "shield",
    category: HardpointCategoryEnum.SHIELDGENERATOR,
    component: { name: "Shield", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

describe("computeShieldStats", () => {
  it("returns empty stats when there are no shields", () => {
    const stats = computeShieldStats([]);

    expect(stats.hasData).toBe(false);
    expect(stats.shieldCount).toBe(0);
    expect(stats.totalHp).toBe(0);
  });

  it("sums HP and regen across shields", () => {
    const stats = computeShieldStats([
      shieldHardpoint({ maxHealth: 10000, maxRegen: 1500 }),
      shieldHardpoint({ maxHealth: 5000, maxRegen: 800 }),
    ]);

    expect(stats.shieldCount).toBe(2);
    expect(stats.totalHp).toBe(15000);
    expect(stats.totalRegen).toBe(2300);
    expect(stats.hasData).toBe(true);
  });

  it("scales regen with the shield power ratio and zeroes when unpowered", () => {
    const shields = [shieldHardpoint({ maxHealth: 10000, maxRegen: 1500 })];

    const half = computeShieldStats(shields, 0.5);
    expect(half.totalRegen).toBe(750);
    expect(half.totalHp).toBe(10000); // powered → full HP

    const off = computeShieldStats(shields, 0);
    expect(off.totalRegen).toBe(0);
    expect(off.totalHp).toBe(0); // unpowered → no protection
    expect(off.hasData).toBe(true); // still shown (as 0), not hidden
  });

  it("HP-weights resistances across shields", () => {
    const stats = computeShieldStats([
      shieldHardpoint({
        maxHealth: 3000,
        maxRegen: 0,
        resistance: { physical: { max: 0.4 } },
      }),
      shieldHardpoint({
        maxHealth: 1000,
        maxRegen: 0,
        resistance: { physical: { max: 0.2 } },
      }),
    ]);

    // (0.4·3000 + 0.2·1000) / 4000 = 0.35
    const physical = stats.resistances.find((r) => r.key === "physical");
    expect(physical?.value).toBeCloseTo(0.35);
  });

  it("omits resistance types with no value", () => {
    const stats = computeShieldStats([
      shieldHardpoint({
        maxHealth: 5000,
        maxRegen: 0,
        resistance: { energy: { max: 0.3 } },
      }),
    ]);

    expect(stats.resistances.map((r) => r.key)).toEqual(["energy"]);
  });

  it("treats a missing absorption as fully absorbed", () => {
    const stats = computeShieldStats([
      shieldHardpoint({ maxHealth: 5000, maxRegen: 0 }),
    ]);

    expect(stats.absorptionByType.physical).toBe(1);
    expect(
      stats.absorptions.every((entry) => entry.min === 1 && entry.max === 1),
    ).toBe(true);
  });

  it("exposes the absorption range per damage type", () => {
    const stats = computeShieldStats([
      shieldHardpoint({
        maxHealth: 5000,
        maxRegen: 0,
        absorption: {
          physical: { min: 0, max: 0.45 },
          energy: { min: 1, max: 1 },
        },
      }),
    ]);

    expect(stats.absorptionByType.physical).toBeCloseTo(0.45);

    const physical = stats.absorptions.find((e) => e.key === "physical");
    expect(physical?.min).toBeCloseTo(0);
    expect(physical?.max).toBeCloseTo(0.45);

    // Energy is fully soaked, so nothing reaches the hull through the shield.
    const energy = stats.absorptions.find((e) => e.key === "energy");
    expect(energy?.max).toBeCloseTo(1);
  });

  it("HP-weights absorption across shields", () => {
    const stats = computeShieldStats([
      shieldHardpoint({
        maxHealth: 3000,
        maxRegen: 0,
        absorption: { physical: { max: 0.4 } },
      }),
      shieldHardpoint({
        maxHealth: 1000,
        maxRegen: 0,
        absorption: { physical: { max: 0.8 } },
      }),
    ]);

    // (0.4·3000 + 0.8·1000) / 4000 = 0.5
    expect(stats.absorptionByType.physical).toBeCloseTo(0.5);
  });
});
