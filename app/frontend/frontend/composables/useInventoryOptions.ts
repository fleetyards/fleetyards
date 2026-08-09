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

  const entryTypeOptions = computed<FilterOption[]>(() =>
    INVENTORY_ENTRY_TYPES.map((entryType) => ({
      value: entryType,
      label: t(`labels.logistics.entryTypes.${entryType}`),
    })),
  );

  return {
    categoryOptions,
    unitOptions,
    entryTypeOptions,
  };
};
