import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentArmor,
} from "@/services/fyApi";
import { computeArmorStats } from "./useArmorStats";

function armorHardpoint(
  typeData: ComponentArmor,
  hardpoints: Hardpoint[] = [],
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "armor",
    category: HardpointCategoryEnum.ARMOR,
    component: { name: "Armor", typeData } as Hardpoint["component"],
    hardpoints,
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

const find = (entries: { key: string; value: number }[], key: string) =>
  entries.find((entry) => entry.key === key);

describe("computeArmorStats", () => {
  it("reports no data when the ship carries no armor", () => {
    const stats = computeArmorStats([]);

    expect(stats.hasData).toBe(false);
    expect(stats.health).toBe(0);
    expect(stats.reductions).toEqual([]);
    expect(stats.deflections).toEqual([]);
  });

  it("defaults every damage multiplier to 1 when there is no armor", () => {
    const stats = computeArmorStats([]);

    expect(stats.damageMultiplierByType.physical).toBe(1);
    expect(stats.damageMultiplierByType.energy).toBe(1);
  });

  it("converts damage multipliers into reductions", () => {
    const stats = computeArmorStats([
      armorHardpoint({
        health: 3300,
        damagePhysical: 0.75,
        damageEnergy: 0.6,
      }),
    ]);

    expect(stats.hasData).toBe(true);
    expect(stats.health).toBe(3300);
    expect(find(stats.reductions, "physical")?.value).toBeCloseTo(0.25);
    expect(find(stats.reductions, "energy")?.value).toBeCloseTo(0.4);
  });

  it("reports a negative reduction when armor amplifies a damage type", () => {
    const stats = computeArmorStats([armorHardpoint({ damageEnergy: 1.1 })]);

    expect(find(stats.reductions, "energy")?.value).toBeCloseTo(-0.1);
  });

  it("drops damage types the armor does not affect", () => {
    const stats = computeArmorStats([
      armorHardpoint({ damagePhysical: 0.8, damageThermal: 1 }),
    ]);

    expect(stats.reductions.map((entry) => entry.key)).toEqual(["physical"]);
  });

  it("exposes deflection thresholds separately from reduction", () => {
    const stats = computeArmorStats([
      armorHardpoint({
        damagePhysical: 0.75,
        deflectionPhysical: 11,
        deflectionEnergy: 9,
        deflectionThermal: 0,
      }),
    ]);

    expect(stats.deflections.map((entry) => entry.key)).toEqual([
      "physical",
      "energy",
    ]);
    expect(find(stats.deflections, "physical")?.value).toBe(11);
  });

  it("converts self-resistance multipliers, keeping amplified types negative", () => {
    const stats = computeArmorStats([
      armorHardpoint({
        selfResistancePhysical: 0.81,
        selfResistanceEnergy: 1.21,
        selfResistanceThermal: 1,
      }),
    ]);

    expect(find(stats.selfResistances, "physical")?.value).toBeCloseTo(0.19);
    expect(find(stats.selfResistances, "energy")?.value).toBeCloseTo(-0.21);
    // A multiplier of exactly 1 has no effect, so it is not shown.
    expect(find(stats.selfResistances, "thermal")).toBeUndefined();
  });

  it("reports signature multipliers as deltas", () => {
    const stats = computeArmorStats([
      armorHardpoint({
        signalInfrared: 1.13,
        signalElectromagnetic: 1.13,
        signalCrossSection: 1,
      }),
    ]);

    expect(find(stats.signatures, "infrared")?.value).toBeCloseTo(0.13);
    expect(find(stats.signatures, "crossSection")).toBeUndefined();
  });

  it("finds armor nested under another hardpoint", () => {
    const stats = computeArmorStats([
      {
        id: "parent",
        name: "parent",
        category: HardpointCategoryEnum.UTILITY,
        hardpoints: [armorHardpoint({ health: 900 })],
        createdAt: "",
        updatedAt: "",
      } as Hardpoint,
    ]);

    expect(stats.hasData).toBe(true);
    expect(stats.health).toBe(900);
  });
});
