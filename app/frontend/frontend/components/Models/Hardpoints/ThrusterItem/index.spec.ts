import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointSourceEnum,
  type Hardpoint,
} from "@/services/fyApi";
import Component from "./index.vue";

const thruster = {
  id: "1",
  name: "hardpoint_thruster_retro",
  source: HardpointSourceEnum.GAME_FILES,
  category: HardpointCategoryEnum.RETRO_THRUSTERS,
  maxSize: 2,
  component: {
    id: "c1",
    name: "Retro Thruster",
    subType: "FlexThruster",
    typeData: {
      thrustCapacity: 1_282_107,
      vtolOnly: true,
      gimbal: { minPitch: -90, maxPitch: 90 },
    },
  },
} as unknown as Hardpoint;

describe("HardpointThrusterItem", () => {
  it("shows a ship thruster's VTOL and vectoring rows beside its thrust", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { hardpoints: [thruster] },
    });

    const rows = wrapper
      .findAll(".hardpoint-item__stat")
      .map((row) => row.text());
    expect(rows.some((row) => row.includes("VTOL"))).toBe(true);
    expect(rows.some((row) => row.includes("±90°"))).toBe(true);

    wrapper.unmount();
  });

  it("leads a stack with the thrust of every thruster in it", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { hardpoints: [thruster, { ...thruster, id: "2" }] },
    });

    const one = await mountWithDefaults(Component, {
      props: { hardpoints: [thruster] },
    });
    const value = (mounted: typeof wrapper) =>
      Number(
        mounted
          .get(".hardpoint-headline__value")
          .text()
          .replace(/[^0-9]/g, ""),
      );

    expect(value(wrapper)).toBe(value(one) * 2);

    wrapper.unmount();
    one.unmount();
  });
});
