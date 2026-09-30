import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  HardpointCategoryEnum,
  ComponentMiningModuleActivationEnum,
  type Hardpoint,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => {
  const units: Record<string, string> = {
    percent: "%",
    seconds: " s",
    weaponRange: " m",
  };

  return {
    useI18n: () => ({
      t: (key: string) => key,
      // Like the real helper, which reads 0 as "not available".
      toNumber: (value: number, format?: string) =>
        value ? `${value}${(format && units[format]) || ""}` : "n/a",
    }),
  };
});

function hardpointWith(
  typeData: NonNullable<Hardpoint["component"]>["typeData"],
  category: HardpointCategoryEnum,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "slot",
    category,
    component: { name: "Part", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

// The composable injects page context, so it has to run inside an app.
function statsFor(hardpoint: Hardpoint) {
  let result: ReturnType<typeof useHardpointStats> | undefined;
  createApp({ render: () => null }).runWithContext(() => {
    result = useHardpointStats(hardpoint);
  });

  return result!.value.map(({ label, value }) => [label, value]);
}

describe("useHardpointStats for mining and salvage", () => {
  it("shows a mining laser's power range, reach and modifiers instead of DPS", () => {
    const stats = statsFor(
      hardpointWith(
        {
          beam: true,
          damagePerSecond: { energy: 2340 },
          mining: {
            fracturePowerMin: 117,
            fracturePowerMax: 2340,
            extractionPower: 1850,
            optimalRange: 60,
            maxRange: 180,
            chargeUpTime: 0.1,
            chargeDownTime: 0.1,
            moduleSlots: 1,
            modifiers: {
              instability: -35,
              resistance: 25,
              inertMaterials: -30,
            },
          },
        },
        HardpointCategoryEnum.WEAPONS,
      ),
    );

    expect(stats).toEqual([
      ["labels.hardpoint.mining.fracturePower", "117 - 2340"],
      ["labels.hardpoint.mining.extractionPower", "1850"],
      ["labels.hardpoint.mining.range", "60 - 180 m"],
      ["labels.hardpoint.mining.moduleSlots", "1"],
      ["labels.hardpoint.mining.chargeTime", "0.1 / 0.1 s"],
      ["labels.hardpoint.mining.modifiers.instability", "-35%"],
      ["labels.hardpoint.mining.modifiers.resistance", "+25%"],
      ["labels.hardpoint.mining.modifiers.inertMaterials", "-30%"],
    ]);
  });

  it("shows an instant charge as zero seconds", () => {
    const stats = statsFor(
      hardpointWith(
        { beam: true, mining: { fracturePowerMax: 100, chargeUpTime: 0.5 } },
        HardpointCategoryEnum.WEAPONS,
      ),
    );

    expect(stats).toContainEqual([
      "labels.hardpoint.mining.chargeTime",
      "0.5 / 0 s",
    ]);
  });

  it("shows an active module's effect, uses and duration", () => {
    const stats = statsFor(
      hardpointWith(
        {
          miningModule: true,
          activation: ComponentMiningModuleActivationEnum.ACTIVE,
          charges: 7,
          duration: 15,
          fracturePower: 50,
          modifiers: { instability: 10, resistance: -15.5 },
        },
        HardpointCategoryEnum.UTILITY,
      ),
    );

    expect(stats).toEqual([
      ["labels.hardpoint.mining.activation", "labels.hardpoint.mining.active"],
      ["labels.hardpoint.mining.fracturePower", "+50%"],
      ["labels.hardpoint.mining.charges", "7"],
      ["labels.hardpoint.mining.duration", "15 s"],
      ["labels.hardpoint.mining.modifiers.instability", "+10%"],
      ["labels.hardpoint.mining.modifiers.resistance", "-15.5%"],
    ]);
  });

  it("shows a salvage modifier's multipliers", () => {
    const stats = statsFor(
      hardpointWith(
        {
          salvageModifier: true,
          salvageSpeed: 0.6,
          radius: 1.5,
          extractionEfficiency: 0.9,
        },
        HardpointCategoryEnum.UTILITY,
      ),
    );

    expect(stats).toEqual([
      ["labels.hardpoint.salvage.salvageSpeed", "0.6×"],
      ["labels.hardpoint.salvage.radius", "1.5×"],
      ["labels.hardpoint.salvage.extractionEfficiency", "90%"],
    ]);
  });

  it("still shows a plain utility item's capacity", () => {
    expect(
      statsFor(hardpointWith({ capacity: 32 }, HardpointCategoryEnum.UTILITY)),
    ).toHaveLength(1);
  });
});
