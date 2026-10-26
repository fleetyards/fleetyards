import { inventoryCategoryForEquipment } from "@/frontend/composables/useInventoryOptions";
import {
  type ItemPickerEntry,
  type ItemPickerSelection,
} from "@/frontend/components/Logistics/types";
import { InventoryCategoryEnum } from "@/services/fyApi";

/**
 * What a catalogue record is filed as. A piece of equipment has one category
 * whichever slice of the catalogue it was found in.
 */
export const catalogueSelection = (
  entry: ItemPickerEntry,
): ItemPickerSelection => {
  const category =
    entry.type === "Equipment"
      ? (inventoryCategoryForEquipment(
          entry.record.equipmentType,
        ) as InventoryCategoryEnum)
      : entry.type === "Component"
        ? InventoryCategoryEnum.COMPONENT
        : InventoryCategoryEnum.COMMODITY;

  return {
    item: {
      type: entry.type,
      id: entry.record.id,
      name: entry.record.name,
      counted: entry.type === "Commodity" ? entry.record.counted : undefined,
    },
    name: entry.record.name,
    category,
  };
};
