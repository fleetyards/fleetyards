import { type FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

export const INVENTORY_CATEGORIES = [
  "commodity",
  "component",
  "weapon",
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
