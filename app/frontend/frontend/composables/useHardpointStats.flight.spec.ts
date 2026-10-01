import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  HardpointCategoryEnum,
  type ComponentController,
  type Hardpoint,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => (key === "number.format.separator" ? "," : key),
    toNumber: (value: number) => String(value),
  }),
}));

function controller(typeData: ComponentController): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "controller",
    category: HardpointCategoryEnum.CONTROLLER,
    component: { name: "Blade", typeData } as Hardpoint["component"],
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

const valueOf = (stats: ReturnType<typeof statsFor>, key: string) =>
  stats.find(
    (stat) => stat.label === `labels.hardpoint.flightControllers.${key}`,
  )?.value;

describe("useHardpointStats for flight controllers", () => {
  const blade = {
    scmSpeed: 262,
    scmSpeedBoosted: 610,
    maxSpeed: 1425,
    angularVelocity: { pitch: 53, yaw: 48, roll: 190 },
    boostedAngularVelocity: { pitch: 63.6, yaw: 57.6, roll: 228 },
    boostCapacitor: {
      capacity: 20,
      regenPerSecond: 0.75,
      regenDelay: 0.2,
      rampUpTime: 0.4,
      rampDownTime: 0.2,
    },
  };

  it("shows speeds, rotation and the boost capacitor", () => {
    const stats = statsFor(controller(blade));

    expect(stats[0]).toMatchObject({
      label: "labels.hardpoint.flightControllers.scmSpeed",
      primary: true,
    });
    expect(valueOf(stats, "rotation")).toBe("53 / 48 / 190 °/s");
    expect(valueOf(stats, "boostedRotation")).toBe("64 / 58 / 228 °/s");
    expect(valueOf(stats, "boostCapacity")).toBe("20");
    expect(valueOf(stats, "boostRegen")).toBe("0,75/s");
    expect(valueOf(stats, "boostRamp")).toBe("0,4 / 0,2 s");
  });

  it("writes a zero ramp as 0 rather than not available", () => {
    const stats = statsFor(
      controller({
        ...blade,
        boostCapacitor: { capacity: 20, rampUpTime: 0.6, rampDownTime: 0 },
      }),
    );

    expect(valueOf(stats, "boostRamp")).toBe("0,6 / 0 s");
  });

  it("groups a large capacity and keeps a fractional regen", () => {
    const stats = statsFor(
      controller({
        ...blade,
        boostCapacitor: { capacity: 2800, regenPerSecond: 1.25 },
      }),
    );

    expect(valueOf(stats, "boostCapacity")).toBe("2\u202F800");
    expect(valueOf(stats, "boostRegen")).toBe("1,25/s");
  });

  it("writes a fixed rotation axis as 0", () => {
    const stats = statsFor(
      controller({
        ...blade,
        angularVelocity: { pitch: 40, yaw: 0, roll: 90 },
      }),
    );

    expect(valueOf(stats, "rotation")).toBe("40 / 0 / 90 °/s");
  });

  it("leaves a controller without speeds alone", () => {
    expect(statsFor(controller({ signatureEm: 10 }))).toEqual([]);
  });
});
