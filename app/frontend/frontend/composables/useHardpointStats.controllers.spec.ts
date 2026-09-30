import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  ComponentShieldFaceTypeEnum,
  HardpointCategoryEnum,
  type Hardpoint,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

function controllerHardpoint(typeData: Record<string, unknown>): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "controller",
    category: HardpointCategoryEnum.CONTROLLER,
    component: {
      name: "Controller",
      typeData,
    } as unknown as Hardpoint["component"],
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

describe("useHardpointStats for controllers", () => {
  it("shows a quadrant shield and its reconfiguration cooldown", () => {
    expect(
      statsFor(
        controllerHardpoint({
          faceType: ComponentShieldFaceTypeEnum.QUADRANT,
          reconfigurationCooldown: 2.5,
        }),
      ).map((stat) => stat.value),
    ).toEqual(["labels.hardpoint.controllers.faces.quadrant", "2.5 s"]);
  });

  it("leaves the reconfiguration cooldown off a bubble shield", () => {
    expect(
      statsFor(
        controllerHardpoint({
          faceType: ComponentShieldFaceTypeEnum.BUBBLE,
          reconfigurationCooldown: 2.5,
        }),
      ).map((stat) => stat.value),
    ).toEqual(["labels.hardpoint.controllers.faces.bubble"]);
  });

  it("shows a missile controller's armed missiles, and a zero cooldown as 0 s", () => {
    expect(
      statsFor(
        controllerHardpoint({
          maxArmedMissiles: 4,
          launchCooldown: 0,
          lockAngle: 18,
        }),
      ).map((stat) => stat.value),
    ).toEqual(["4", "0 s", "18°"]);
  });
});
