import { describe, expect, it } from "vitest";
import {
  ComponentShieldFaceTypeEnum,
  HardpointCategoryEnum,
  type Hardpoint,
} from "@/services/fyApi";
import { computeControllerStats } from "./useControllerStats";

function hardpoint(
  category: HardpointCategoryEnum,
  typeData: Record<string, unknown>,
  children: Hardpoint[] = [],
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "port",
    category,
    component: {
      name: "Controller",
      typeData,
    } as unknown as Hardpoint["component"],
    hardpoints: children,
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

describe("computeControllerStats", () => {
  it("reads the shield face type and missile lock capacity off the controllers", () => {
    const stats = computeControllerStats([
      hardpoint(HardpointCategoryEnum.CONTROLLER, {
        faceType: ComponentShieldFaceTypeEnum.QUADRANT,
        reconfigurationCooldown: 2.5,
      }),
      hardpoint(HardpointCategoryEnum.CONTROLLER, {
        maxArmedMissiles: 8,
        launchCooldown: 0,
      }),
    ]);

    expect(stats).toEqual({
      shieldFaceType: ComponentShieldFaceTypeEnum.QUADRANT,
      reconfigurationCooldown: 2.5,
      maxArmedMissiles: 8,
      launchCooldown: 0,
    });
  });

  it("finds a controller nested in a module", () => {
    const stats = computeControllerStats([
      hardpoint(HardpointCategoryEnum.MODULE, {}, [
        hardpoint(HardpointCategoryEnum.CONTROLLER, {
          faceType: ComponentShieldFaceTypeEnum.BUBBLE,
        }),
      ]),
    ]);

    expect(stats.shieldFaceType).toBe(ComponentShieldFaceTypeEnum.BUBBLE);
  });

  it("ignores a flight controller and anything that is not a controller", () => {
    expect(
      computeControllerStats([
        hardpoint(HardpointCategoryEnum.CONTROLLER, { scmSpeed: 200 }),
        hardpoint(HardpointCategoryEnum.WEAPONS, { maxArmedMissiles: 4 }),
      ]),
    ).toEqual({});
  });
});
