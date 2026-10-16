import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { Model, WeaponRack } from "@/services/fyApi";
import Component from "./index.vue";

const model = (weaponRacks?: WeaponRack[]) =>
  ({ id: "model-1", weaponRacks }) as unknown as Model;

const constellationRack: WeaponRack = {
  key: "Weapon_Rack_single_2Slot",
  count: 4,
  slots: [
    {
      minSize: 2,
      maxSize: 2,
      types: [{ type: "WeaponPersonal", subTypes: [] }],
    },
    {
      minSize: 1,
      maxSize: 1,
      types: [{ type: "WeaponPersonal", subTypes: [] }],
    },
    {
      minSize: 0,
      maxSize: 1,
      types: [{ type: "WeaponPersonal", subTypes: ["Gadget"] }],
    },
  ],
};

describe("ModelWeaponRacks", () => {
  it("counts every slot across the racks on board", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model: model([constellationRack]) },
    });

    const card = wrapper.get("[data-test='weapon-racks']");
    expect(card.text()).toContain("12");
    expect(card.text()).toContain("4x");
    expect(wrapper.findAll("[data-test='weapon-rack-slot']")).toHaveLength(3);
  });

  it("names what a slot takes and how large", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model: model([constellationRack]) },
    });

    const slots = wrapper
      .findAll("[data-test='weapon-rack-slot']")
      .map((slot) => slot.text());

    expect(slots[0]).toContain("Weapon");
    expect(slots[0]).toContain("S2");
    expect(slots[2]).toContain("Gadget");
    expect(slots[2]).toContain("up to S1");
  });

  it("says when a slot is kept for one kind of gadget", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        model: model([
          {
            key: "Weapon_Rack_DRAK_Clipper",
            count: 1,
            slots: [
              {
                minSize: 1,
                maxSize: 1,
                types: [{ type: "WeaponPersonal", subTypes: ["Gadget"] }],
                requiredTags: ["multitool"],
              },
            ],
          },
        ]),
      },
    });

    expect(wrapper.get("[data-test='weapon-rack-slot']").text()).toContain(
      "Multi-Tool only",
    );
  });

  it("shows nothing for a ship without racks", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model: model() },
    });

    expect(wrapper.find("[data-test='weapon-racks']").exists()).toBe(false);
  });
});
