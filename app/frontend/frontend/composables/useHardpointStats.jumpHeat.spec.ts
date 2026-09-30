import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  HardpointCategoryEnum,
  type ComponentQuantumDrive,
  type Hardpoint,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

function quantumDrive(typeData: ComponentQuantumDrive): Hardpoint {
  return {
    id: "qd",
    name: "quantum drive",
    category: HardpointCategoryEnum.QUANTUMDRIVE,
    component: { name: "Drive", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

function jumpHeatRow(typeData: ComponentQuantumDrive) {
  let result: ReturnType<typeof useHardpointStats> | undefined;
  createApp({ render: () => null }).runWithContext(() => {
    result = useHardpointStats(quantumDrive(typeData));
  });

  return result!.value.find(
    (stat) => stat.label === "labels.hardpoint.quantumDrives.jumpHeat",
  );
}

describe("useHardpointStats for a quantum drive's jump heat", () => {
  it("shows one figure when every phase puts out the same heat", () => {
    const heat = 6000;

    expect(
      jumpHeatRow({
        jumpHeat: {
          preRampUp: heat,
          rampUp: heat,
          inFlight: heat,
          rampDown: heat,
          postRampDown: heat,
        },
      })?.value,
    ).toBe("6000");
  });

  it("shows every phase in order when they differ", () => {
    expect(
      jumpHeatRow({
        jumpHeat: {
          preRampUp: 573,
          rampUp: 600,
          inFlight: 6000,
          rampDown: 600,
          postRampDown: 573,
        },
      })?.value,
    ).toBe("573 / 600 / 6000 / 600 / 573");
  });

  it("shows nothing for a drive without jump heat", () => {
    expect(jumpHeatRow({ driveSpeed: 1 })).toBeUndefined();
  });
});
