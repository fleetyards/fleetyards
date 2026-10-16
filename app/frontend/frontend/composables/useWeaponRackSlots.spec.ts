import type { WeaponRack, WeaponRackSlot } from "@/services/fyApi";
import {
  RackSlotCategory,
  groupRackSlots,
} from "@/frontend/composables/useWeaponRackSlots";

const weapon = (
  minSize: number,
  maxSize: number,
  subTypes: string[] = [],
): WeaponRackSlot => ({
  minSize,
  maxSize,
  types: [{ type: "WeaponPersonal", subTypes }],
});

const rack = (
  key: string,
  count: number,
  slots: WeaponRackSlot[],
): WeaponRack => ({
  key,
  count,
  slots,
});

describe("groupRackSlots", () => {
  it("multiplies a rack's slots by how often it is placed", () => {
    const groups = groupRackSlots([
      rack("Weapon_Rack_single_2Slot", 4, [
        weapon(2, 2),
        weapon(1, 1),
        weapon(0, 1, ["Gadget"]),
      ]),
    ]);

    expect(
      groups.map((group) => [group.categories, group.maxSize, group.count]),
    ).toEqual([
      [[RackSlotCategory.WEAPON], 2, 4],
      [[RackSlotCategory.WEAPON], 1, 4],
      [[RackSlotCategory.GADGET], 1, 4],
    ]);
  });

  it("merges the same slot across different racks", () => {
    const groups = groupRackSlots([
      rack("A", 1, [weapon(2, 3)]),
      rack("B", 2, [weapon(2, 3), weapon(2, 3)]),
    ]);

    expect(groups).toHaveLength(1);
    expect(groups[0].count).toBe(5);
    expect(groups[0].share).toBe(100);
  });

  it("keeps a slot that takes cargo and armour as one of each", () => {
    const groups = groupRackSlots([
      rack("Smuggling", 1, [
        {
          minSize: 1,
          maxSize: 4,
          types: [
            { type: "Cargo", subTypes: [] },
            { type: "Misc", subTypes: [] },
            { type: "Char_Armor_Torso", subTypes: [] },
            { type: "Container", subTypes: ["Box"] },
          ],
        },
      ]),
    ]);

    expect(groups[0].categories).toEqual([
      RackSlotCategory.CARGO,
      RackSlotCategory.CARRIABLE,
      RackSlotCategory.ARMOR,
    ]);
  });

  it("keeps a slot reserved for multitools apart from an open gadget slot", () => {
    const groups = groupRackSlots([
      rack("Clipper", 1, [
        { ...weapon(1, 1, ["Gadget"]), requiredTags: ["multitool"] },
        weapon(1, 1, ["Gadget"]),
        { ...weapon(1, 1, ["Gadget"]), requiredTags: ["weapon_port_01"] },
      ]),
    ]);

    expect(groups.map((group) => [group.restriction, group.count])).toEqual([
      [undefined, 2],
      ["multitool", 1],
    ]);
  });

  it("gives nothing for no racks", () => {
    expect(groupRackSlots([])).toEqual([]);
  });
});
