import { type FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export const INVENTORY_CATEGORIES = [
  "commodity",
  "component",
  "weapon",
  "armor",
  "clothing",
  "tool",
  "container",
  "equipment",
  "ammunition",
  "consumable",
  "other",
] as const;

export const INVENTORY_UNITS = ["scu", "units"] as const;

/**
 * Mirrors InventoryLedgerEntry::UNITS_BY_CATEGORY — the API rejects any other
 * pairing, so keep the two in step.
 */
export const INVENTORY_UNITS_BY_CATEGORY: Record<
  string,
  readonly (typeof INVENTORY_UNITS)[number][]
> = {
  commodity: ["scu"],
  component: ["units"],
  weapon: ["units"],
  equipment: ["units"],
  ammunition: ["units"],
  consumable: ["units"],
  other: ["scu", "units"],
  armor: ["units"],
  clothing: ["units"],
  tool: ["units"],
  container: ["units"],
};

/**
 * The units a position may be recorded in.
 *
 * The category answers for almost everything, but the game hands out 56
 * commodities a piece at a time, and a crafting recipe asks for a number of
 * them rather than a volume. `counted` widens the pairing rather than
 * replacing it: those are still sold by the crate, and every commodity
 * position ever recorded is in SCU.
 *
 * A free-text position points at no catalogue row, so it cannot be counted and
 * keeps the SCU-only rule -- the same answer the API gives.
 */
export const unitsForCategory = (category?: string, counted?: boolean) => {
  const allowed =
    INVENTORY_UNITS_BY_CATEGORY[category ?? ""] ?? INVENTORY_UNITS;

  if (!counted || allowed.includes("units")) return allowed;

  return [
    ...allowed,
    "units",
  ] as const satisfies readonly (typeof INVENTORY_UNITS)[number][];
};

/**
 * Which slice of the equipment table each category picks from. One table backs
 * them all -- the game files magazines as weapon attachments, so ammunition is
 * not a catalogue of its own. Without it a picker offers every type in the
 * table, mostly armour and clothing, whatever category is selected.
 *
 * Mirrors InventoryLedgerEntry::CATEGORIES_BY_EQUIPMENT_TYPE, which files a
 * hangar deposit, so keep the two in step.
 */
export const INVENTORY_EQUIPMENT_TYPES: Record<string, string[]> = {
  weapon: ["weapon"],
  armor: ["armor", "undersuit"],
  clothing: ["clothing"],
  tool: ["tool", "mining_gadget", "hacking_tool"],
  container: ["container"],
  ammunition: ["weapon_attachment"],
  equipment: ["medical"],
  consumable: ["sustenance", "medical"],
  other: ["carryable", "flair"],
};

/**
 * The categories whose slice is worn, which the picker narrows by slot as well.
 */
export const INVENTORY_WORN_CATEGORIES = ["armor", "clothing"];

/**
 * The one category a piece of equipment is filed under: the first whose slice
 * holds its type. Medical sits in two slices, and equipment comes first, which
 * is where it was filed before consumables could pick it. Contract progress
 * matches deposits on the category, so browsing to a medpen under consumables
 * must not file it somewhere a contract asking for it would never look.
 */
export const inventoryCategoryForEquipment = (equipmentType?: string | null) =>
  Object.keys(INVENTORY_EQUIPMENT_TYPES).find((category) =>
    INVENTORY_EQUIPMENT_TYPES[category].includes(equipmentType ?? ""),
  ) ?? "equipment";

export const INVENTORY_ENTRY_TYPES = ["deposit", "withdrawal"] as const;

export const useInventoryOptions = () => {
  const { t } = useI18n();

  const categoryOptions = computed<FilterOption[]>(() =>
    INVENTORY_CATEGORIES.map((category) => ({
      value: category,
      label: t(`labels.logistics.categories.${category}`),
    })),
  );

  const unitOptions = computed<FilterOption[]>(() =>
    INVENTORY_UNITS.map((unit) => ({
      value: unit,
      label: t(`labels.logistics.units.${unit}`),
    })),
  );

  const unitOptionsFor = (
    category: MaybeRefOrGetter<string | undefined>,
    counted?: MaybeRefOrGetter<boolean | undefined>,
  ) =>
    computed<FilterOption[]>(() =>
      unitsForCategory(toValue(category), toValue(counted)).map((unit) => ({
        value: unit,
        label: t(`labels.logistics.units.${unit}`),
      })),
    );

  const entryTypeOptions = computed<FilterOption[]>(() =>
    INVENTORY_ENTRY_TYPES.map((entryType) => ({
      value: entryType,
      label: t(`labels.logistics.entryTypes.${entryType}`),
    })),
  );

  return {
    categoryOptions,
    unitOptions,
    unitOptionsFor,
    entryTypeOptions,
  };
};
