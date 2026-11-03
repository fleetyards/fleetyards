import {
  EquipmentTypeEnum,
  type Component,
  type ComponentQuery,
  type Equipment,
  type EquipmentQuery,
  type EquipmentSlotEnum,
} from "@/services/fyApi";

// What a compare set holds one of. `key` tells two items apart, `query` asks the
// catalogue for more of the same, and `label` names it to the reader.
export type CompareCategory<Q> = {
  key: string;
  label: string;
  query: Q;
};

export type ComponentCompareCategory = CompareCategory<ComponentQuery>;
export type EquipmentCompareCategory = CompareCategory<EquipmentQuery>;

export const componentCompareCategory = (
  component: Component,
  label: (category: string) => string,
): ComponentCompareCategory | undefined => {
  if (!component.category) return undefined;

  return {
    key: component.category,
    label: label(component.category),
    query: { categoryIn: [component.category] },
  };
};

const WORN_TYPES: string[] = [
  EquipmentTypeEnum.ARMOR,
  EquipmentTypeEnum.UNDERSUIT,
  EquipmentTypeEnum.CLOTHING,
];

// The equipment type alone is too broad to compare across: a pistol beside a
// sniper rifle, or a helmet beside a chest plate, share almost no figure. So
// anything worn narrows to its slot and the rest to its item type -- rifle,
// pistol, SMG -- each only where the item has one. Not the weapon class: that
// is ballistic or energy, and files the pistol with the sniper rifle again.
export const equipmentCompareCategory = (
  item: Equipment,
): EquipmentCompareCategory | undefined => {
  const type = item.equipmentType;
  if (!type) return undefined;

  const base = {
    key: type,
    label: item.equipmentTypeLabel ?? type,
    query: { equipmentTypeIn: [type] } as EquipmentQuery,
  };

  if (WORN_TYPES.includes(type) && item.slot) {
    return {
      key: `${type}:${item.slot}`,
      label: item.slotLabel ?? item.slot,
      query: { ...base.query, slotIn: [item.slot as EquipmentSlotEnum] },
    };
  }

  if (item.itemType) {
    return {
      key: `${type}:${item.itemType}`,
      label: item.itemTypeLabel ?? item.itemType,
      query: { ...base.query, itemTypeIn: [item.itemType] },
    };
  }

  return base;
};
