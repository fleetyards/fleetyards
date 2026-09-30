import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  ComponentShieldFaceTypeEnum,
  HardpointCategoryEnum,
  type Hardpoint,
} from "@/services/fyApi";
import Component from "./index.vue";

function hardpoint(
  category: HardpointCategoryEnum,
  typeData: Record<string, unknown>,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "port",
    category,
    component: { name: "Part", typeData } as unknown as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

const shipWith = (reconfigurationCooldown: number) => [
  hardpoint(HardpointCategoryEnum.SHIELDGENERATOR, {
    maxHealth: 1000,
    maxRegen: 50,
  }),
  hardpoint(HardpointCategoryEnum.CONTROLLER, {
    faceType: ComponentShieldFaceTypeEnum.QUADRANT,
    reconfigurationCooldown,
  }),
];

describe("ModelDefenseMetrics shield faces", () => {
  it("shows a quadrant shield's reconfiguration cooldown", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { hardpoints: shipWith(2.5) },
    });

    expect(
      wrapper.find("[data-test='shield-reconfiguration']").text(),
    ).toContain("2,5 s");
  });

  it("shows a zero reconfiguration cooldown as 0 s", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { hardpoints: shipWith(0) },
    });

    expect(
      wrapper.find("[data-test='shield-reconfiguration']").text(),
    ).toContain("0 s");
  });
});
