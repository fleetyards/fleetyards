import { describe, expect, it } from "vitest";
import {
  EquipmentTypeEnum,
  type Component,
  type Equipment,
} from "@/services/fyApi";
import { componentCompareCategory, equipmentCompareCategory } from "./category";

const equipment = (fields: Partial<Equipment>) => fields as Equipment;

describe("equipmentCompareCategory", () => {
  it("narrows a weapon to its item type, not its class", () => {
    const category = equipmentCompareCategory(
      equipment({
        equipmentType: EquipmentTypeEnum.WEAPON,
        weaponClass: "ballistic",
        itemType: "rifle",
        itemTypeLabel: "Rifle",
      }),
    );

    expect(category?.key).toBe("weapon:rifle");
    expect(category?.label).toBe("Rifle");
    expect(category?.query).toEqual({
      equipmentTypeIn: ["weapon"],
      itemTypeIn: ["rifle"],
    });
  });

  it("narrows anything worn to its slot", () => {
    const helmet = equipmentCompareCategory(
      equipment({ equipmentType: EquipmentTypeEnum.ARMOR, slot: "helmet" }),
    );
    const chest = equipmentCompareCategory(
      equipment({ equipmentType: EquipmentTypeEnum.ARMOR, slot: "torso" }),
    );

    expect(helmet?.key).not.toBe(chest?.key);
    expect(helmet?.query).toEqual({
      equipmentTypeIn: ["armor"],
      slotIn: ["helmet"],
    });
  });

  it("falls back to the item type, then the equipment type", () => {
    expect(
      equipmentCompareCategory(
        equipment({
          equipmentType: EquipmentTypeEnum.TOOL,
          itemType: "multitool",
        }),
      )?.key,
    ).toBe("tool:multitool");
    expect(
      equipmentCompareCategory(
        equipment({ equipmentType: EquipmentTypeEnum.TOOL }),
      )?.key,
    ).toBe("tool");
  });

  it("has no category for an item without a type", () => {
    expect(equipmentCompareCategory(equipment({}))).toBeUndefined();
  });
});

describe("componentCompareCategory", () => {
  it("files a component under its category", () => {
    const category = componentCompareCategory(
      { category: "quantum_drives" } as Component,
      (value) => `label:${value}`,
    );

    expect(category).toEqual({
      key: "quantum_drives",
      label: "label:quantum_drives",
      query: { categoryIn: ["quantum_drives"] },
    });
  });
});
