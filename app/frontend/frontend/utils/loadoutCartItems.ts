import {
  type CartItemCreateInput,
  InventoryItemTypeEnum,
  type LoadoutSlot,
} from "@/services/fyApi";

// Every part a loadout fits in place of the stock one, as cart lines: the same
// part in several hardpoints is one line with that many. Nested ports count
// too, since a swapped mount brings guns of its own.
export const nonStockCartItems = (
  slots: LoadoutSlot[] = [],
): CartItemCreateInput[] => {
  const counts = new Map<string, number>();

  const walk = (slot: LoadoutSlot) => {
    if (slot.fitted && slot.fitted.id !== slot.stock?.id) {
      counts.set(slot.fitted.id, (counts.get(slot.fitted.id) ?? 0) + 1);
    }

    slot.slots.forEach(walk);
  };

  slots.forEach(walk);

  return [...counts].map(([itemId, quantity]) => ({
    itemType: InventoryItemTypeEnum.COMPONENT,
    itemId,
    quantity,
  }));
};
