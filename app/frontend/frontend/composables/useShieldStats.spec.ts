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
});
