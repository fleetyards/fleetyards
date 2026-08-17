// The hangar and fleet endpoints each generate their own itemType enum, so the
// pickers speak in this literal union, which is assignable to both.
export type PickedItemType = "Component" | "Commodity" | "Equipment";

export type PickedItem = {
  type: PickedItemType;
  id: string;
  name: string;
};
