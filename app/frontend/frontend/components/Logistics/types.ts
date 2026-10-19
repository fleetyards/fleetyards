import type {
  Commodity,
  Component as GameComponent,
  Equipment,
  InventoryCategoryEnum,
} from "@/services/fyApi";

// The hangar and fleet endpoints each generate their own itemType enum, so the
// pickers speak in this literal union, which is assignable to both.
export type PickedItemType = "Component" | "Commodity" | "Equipment";

export type PickedItem = {
  type: PickedItemType;
  id: string;
  name: string;
  /** Whether the game counts it in pieces, which is what puts `units` on offer. */
  counted?: boolean;
};

// One result of the item picker. Each catalogue has its own record shape, so
// the kind travels with it and decides how the row is drawn.
export type ItemPickerEntry =
  | { type: "Component"; record: GameComponent }
  | { type: "Commodity"; record: Commodity }
  | { type: "Equipment"; record: Equipment };

// What the item picker hands back: the goods and where they are filed. `item`
// is absent for goods the catalogue does not carry, which are named by hand.
export type ItemPickerSelection = {
  item?: PickedItem;
  name: string;
  category: InventoryCategoryEnum;
};

// A crafted part: the recipe it was made from and the grade of material in each
// of the recipe's graded slots, keyed by the slot's position. A grade stays
// undefined until it is entered.
export type CraftedSelection = {
  blueprintId: string;
  qualities: Record<string, number | undefined>;
};
