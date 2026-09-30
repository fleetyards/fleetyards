import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  HardpointCategoryEnum,
  type ComponentWeapon,
  type Hardpoint,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => (key === "number.format.separator" ? "," : key),
    toNumber: (value: number) => String(value),
  }),
}));

function gunHardpoint(typeData: ComponentWeapon): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "gun",
    category: HardpointCategoryEnum.WEAPONS,
    component: { name: "Gun", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

function statsFor(hardpoint: Hardpoint) {
  let result: ReturnType<typeof useHardpointStats> | undefined;
  createApp({ render: () => null }).runWithContext(() => {
    result = useHardpointStats(hardpoint);
  });

  return result!.value;
}

const valueOf = (stats: { label: string; value: string }[], label: string) =>
  stats.find((stat) => stat.label === label)?.value;

describe("useHardpointStats for a gun's gimbal mode and aim assist", () => {
  it("shows the fire rate in gimbal mode and the aim-assist cones", () => {
    const stats = statsFor(
      gunHardpoint({
        fireRate: 600,
        gimbalMode: {
          fireRateMultiplier: 0.85,
          spreadMinMultiplier: 0.5,
          spreadMaxMultiplier: 0.5,
        },
        aimAssist: {
          nudgeAngle: 2.25,
          closeOuterAngle: 16,
          closeRangeMin: 75,
          closeRangeMax: 150,
        },
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.weapons.gimbalFireRate")).toBe(
      "510",
    );
    expect(valueOf(stats, "labels.hardpoint.weapons.gimbalSpread")).toBe(
      "×0,5",
    );
    expect(valueOf(stats, "labels.hardpoint.weapons.aimAssist")).toBe("2,25°");
    expect(valueOf(stats, "labels.hardpoint.weapons.closeAimAssist")).toBe(
      "16° (75–150 m)",
    );
  });

  it("shows a spread change on the maximum alone", () => {
    const stats = statsFor(
      gunHardpoint({
        gimbalMode: { spreadMinMultiplier: 1, spreadMaxMultiplier: 0.5 },
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.weapons.gimbalSpread")).toBe(
      "×1 / ×0,5",
    );
  });

  it("does not invent a close-range start the record leaves out", () => {
    const stats = statsFor(
      gunHardpoint({ aimAssist: { closeOuterAngle: 16, closeRangeMax: 150 } }),
    );

    expect(valueOf(stats, "labels.hardpoint.weapons.closeAimAssist")).toBe(
      "16° (≤ 150 m)",
    );
  });

  it("leaves out a gimbal-mode figure that changes nothing", () => {
    const stats = statsFor(
      gunHardpoint({
        fireRate: 600,
        gimbalMode: { fireRateMultiplier: 1, spreadMinMultiplier: 1 },
      }),
    );

    expect(
      valueOf(stats, "labels.hardpoint.weapons.gimbalFireRate"),
    ).toBeUndefined();
    expect(
      valueOf(stats, "labels.hardpoint.weapons.gimbalSpread"),
    ).toBeUndefined();
    expect(
      valueOf(stats, "labels.hardpoint.weapons.aimAssist"),
    ).toBeUndefined();
  });
});
