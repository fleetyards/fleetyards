import {
  type CartItemCreateInput,
  HardpointCategoryEnum,
  InventoryItemTypeEnum,
  type LoadoutComponentRef,
  type LoadoutSlot,
} from "@/services/fyApi";
import { type FittedSlot } from "@/frontend/composables/useComponentFitting";

type Node = {
  part?: LoadoutComponentRef;
  stock?: LoadoutComponentRef;
  children: Node[];
};

// Every part a fitting holds in place of the stock one, as cart lines: the same
// part in several hardpoints is one line with that many. Nested ports count
// too, since a swapped mount brings guns of its own. Modules are not
// catalogue items, so they stay out.
const nonStock = (nodes: Node[]): CartItemCreateInput[] => {
  const counts = new Map<string, number>();

  const walk = (node: Node) => {
    const { part, stock } = node;
    if (
      part &&
      part.id !== stock?.id &&
      part.category !== HardpointCategoryEnum.MODULE
    ) {
      counts.set(part.id, (counts.get(part.id) ?? 0) + 1);
    }

    node.children.forEach(walk);
  };

  nodes.forEach(walk);

  return [...counts].map(([itemId, quantity]) => ({
    itemType: InventoryItemTypeEnum.COMPONENT,
    itemId,
    quantity,
  }));
};

const fromSlot = (slot: LoadoutSlot): Node => ({
  part: slot.fitted,
  stock: slot.stock,
  children: slot.slots.map(fromSlot),
});

const fromFitted = (entry: FittedSlot): Node => ({
  part: entry.content,
  stock: entry.slot.stock,
  children: entry.children.map(fromFitted),
});

// A saved loadout, as the slots endpoint describes it.
export const nonStockCartItems = (slots: LoadoutSlot[] = []) =>
  nonStock(slots.map(fromSlot));

// The fitting as it stands in the editor, saved or not.
export const nonStockFittedItems = (tree: FittedSlot[] = []) =>
  nonStock(tree.map(fromFitted));
