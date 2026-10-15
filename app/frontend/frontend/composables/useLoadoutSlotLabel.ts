import { useI18n } from "@/shared/composables/useI18n";

// The same keywords `ModuleHardpoint.derive_slot` reads a slot's position
// from, bow and stern being the front and rear by another name.
const SLOT_POSITIONS = [
  ["front", "front"],
  ["bow", "front"],
  ["rear", "rear"],
  ["stern", "rear"],
  ["left", "left"],
  ["right", "right"],
] as const;

export const useLoadoutSlotLabel = () => {
  const { t } = useI18n();

  const slotLabel = (slotPath: string) => {
    const slot = slotPath.split("/").pop() || slotPath;
    const position = SLOT_POSITIONS.find(([keyword]) => slot.includes(keyword));

    return t(`labels.vehicleLoadout.slots.${position?.[1] || "default"}`);
  };

  return { slotLabel };
};
