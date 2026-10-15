import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { ModelModule } from "@/services/fyApi";
import Component from "./index.vue";

const modules = [
  { id: "front", name: "Front Cargo", slot: "hardpoint_front_module" },
  { id: "torpedo", name: "Front Torpedo Bay", slot: "hardpoint_front_module" },
  { id: "rear", name: "Rear Cargo", slot: "hardpoint_rear_module" },
  { id: "mystery", name: "Mystery Module" },
] as unknown as ModelModule[];

const mountFitting = (props: {
  ownedIds: string[];
  modelValue?: Record<string, string>;
  editable?: boolean;
}) => mountWithDefaults(Component, { props: { modules, ...props } });

describe("VehicleLoadoutModalFitting", () => {
  it("offers only owned modules, slot by slot", async () => {
    const wrapper = await mountFitting({
      ownedIds: ["front", "rear"],
      editable: true,
    });

    const front = wrapper.get(
      "[data-test='vehicle-loadout-slot-hardpoint_front_module']",
    );
    expect(front.text()).toContain("Front Cargo");
    expect(front.text()).not.toContain("Front Torpedo Bay");
  });

  it("names owned modules that cannot be fitted for want of a slot", async () => {
    const wrapper = await mountFitting({
      ownedIds: ["mystery"],
      editable: true,
    });

    expect(
      wrapper.get("[data-test='vehicle-loadout-unslotted']").text(),
    ).toContain("Mystery Module");
  });

  it("shows a visitor only what is fitted", async () => {
    const wrapper = await mountFitting({
      ownedIds: ["front", "torpedo", "rear"],
      modelValue: { hardpoint_front_module: "torpedo" },
    });

    expect(wrapper.text()).toContain("Front Torpedo Bay");
    expect(wrapper.text()).not.toContain("Front Cargo");
    expect(
      wrapper
        .find("[data-test='vehicle-loadout-slot-hardpoint_rear_module']")
        .exists(),
    ).toBe(false);
  });
});
