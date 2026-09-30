import { describe, expect, it } from "vitest";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import {
  computeCountermeasureStats,
  countermeasureKind,
} from "./useCountermeasureStats";

function hardpoint(
  category: HardpointCategoryEnum,
  component?: { scKey?: string; name?: string; maxAmmo?: number },
  hardpoints: Hardpoint[] = [],
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "hardpoint",
    category,
    component: component
      ? ({
          name: component.name ?? "Launcher",
          scKey: component.scKey,
          typeData: { maxAmmo: component.maxAmmo },
        } as Hardpoint["component"])
      : undefined,
    hardpoints,
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

const launcher = (scKey: string, maxAmmo: number, name?: string) =>
  hardpoint(HardpointCategoryEnum.COUNTERMEASURES, { scKey, maxAmmo, name });

describe("countermeasureKind", () => {
  it("reads flare and decoy keys as decoys", () => {
    expect(countermeasureKind("anvl_asgard_cml_flare")).toBe("decoy");
    expect(countermeasureKind("orig_cml_decoy_small")).toBe("decoy");
  });

  it("reads chaff and noise keys as noise", () => {
    expect(countermeasureKind("anvl_asgard_cml_chaff")).toBe("noise");
    expect(countermeasureKind("anvl_cml_noise_small")).toBe("noise");
  });

  it("returns nothing for an unknown or missing key", () => {
    expect(countermeasureKind("anvl_cml_mystery")).toBeUndefined();
    expect(countermeasureKind(undefined)).toBeUndefined();
  });
});

describe("computeCountermeasureStats", () => {
  it("reports no data when the ship carries no countermeasures", () => {
    const stats = computeCountermeasureStats([
      hardpoint(HardpointCategoryEnum.ARMOR, { scKey: "armor" }),
    ]);

    expect(stats.hasData).toBe(false);
    expect(stats.counts).toEqual([]);
  });

  it("sums the ammo of every launcher per kind", () => {
    const stats = computeCountermeasureStats([
      ...Array.from({ length: 4 }, () => launcher("anvl_asgard_cml_flare", 48)),
      ...Array.from({ length: 4 }, () => launcher("anvl_asgard_cml_chaff", 5)),
    ]);

    expect(stats.hasData).toBe(true);
    expect(stats.counts.map(({ key, value }) => [key, value])).toEqual([
      ["decoy", 192],
      ["noise", 20],
    ]);
  });

  it("classifies by item key, not by the display name", () => {
    const stats = computeCountermeasureStats([
      launcher("orig_m50_cml_flare", 24, "Origin Jumpworks Noise Launcher"),
    ]);

    expect(stats.counts).toEqual([
      expect.objectContaining({ key: "decoy", value: 24 }),
    ]);
  });

  it("finds launchers on nested hardpoints", () => {
    const stats = computeCountermeasureStats([
      hardpoint(HardpointCategoryEnum.TURRET, { scKey: "turret" }, [
        launcher("aegs_idris_cml_chaff", 300),
      ]),
    ]);

    expect(stats.counts).toEqual([
      expect.objectContaining({ key: "noise", value: 300 }),
    ]);
  });

  it("drops a kind with no ammo rather than showing a zero", () => {
    const stats = computeCountermeasureStats([
      launcher("misc_razor_cml_chaff", 2),
      launcher("misc_razor_cml_flare", 0),
      hardpoint(HardpointCategoryEnum.COUNTERMEASURES),
    ]);

    expect(stats.counts.map(({ key }) => key)).toEqual(["noise"]);
  });
});
