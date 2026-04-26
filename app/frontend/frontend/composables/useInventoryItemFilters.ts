import { useFilters } from "@/shared/composables/useFilters";

export type InventoryItemQuery = {
  nameCont?: string;
  categoryEq?: string;
  qualityGteq?: string;
  qualityLteq?: string;
};

export const useInventoryItemFilters = (
  updateCallback?: () => Promise<void>,
) => {
  const { filter, resetFilter, isFilterSelected, filters, getQuery } =
    useFilters<InventoryItemQuery>({
      updateCallback: async () => {
        if (updateCallback) {
          await updateCallback();
        }
      },
    });

  return {
    filter,
    resetFilter,
    isFilterSelected,
    filters,
    getQuery,
  };
};
