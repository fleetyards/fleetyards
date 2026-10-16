import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { ModelModule } from "@/services/fyApi";
import Component from "./index.vue";

const modules = [
  { id: "front", name: "Front Cargo", slot: "hardpoint_front_module" },
  { id: "torpedo", name: "Front Torpedo Bay", slot: "hardpoint_front_module" },
  { id: "rear", name: "Rear Cargo", slot: "hardpoint_rear_module" },
  { id: "mystery", name: "Mystery Module" },
  {
    id: "stock",
    name: "Factory Rear Module",
    slot: "hardpoint_rear_module",
    stock: true,
  },
] as unknown as ModelModule[];

const mountFitting = (props: {
  ownedIds: string[];
  modelValue?: Record<string, string>;
  editable?: boolean;
}) => mountWithDefaults(Component, { props: { modules, ...props } });

describe("VehicleLoadoutModalFitting", () => {
  it("offers every module the slot takes, marked by ownership", async () => {
    const wrapper = await mountFitting({ ownedIds: ["front"], editable: true });

    const rows = wrapper
      .get("[data-test='vehicle-loadout-slot-hardpoint_front_module']")
      .findAll("[data-test='vehicle-loadout-slot-module']")
      .map((row) => row.text());

    expect(rows).toHaveLength(2);
    expect(rows.find((row) => row.includes("Front Cargo"))).toContain("Owned");
    expect(rows.find((row) => row.includes("Front Torpedo Bay"))).toContain(
      "Not owned",
    );
  });

  it("marks the module the hull comes with as stock", async () => {
    const wrapper = await mountFitting({ ownedIds: [], editable: true });

    const rows = wrapper
      .get("[data-test='vehicle-loadout-slot-hardpoint_rear_module']")
      .findAll("[data-test='vehicle-loadout-slot-module']")
      .map((row) => row.text());

    expect(rows.find((row) => row.includes("Factory Rear Module"))).toContain(
      "Stock",
    );
    expect(rows.find((row) => row.includes("Rear Cargo"))).toContain(
      "Not owned",
    );
  });

  it("leaves out a module the game files give no slot", async () => {
    const wrapper = await mountFitting({ ownedIds: [], editable: true });

    expect(wrapper.text()).not.toContain("Mystery Module");
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
