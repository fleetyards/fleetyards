import { useFilters } from "@/shared/composables/useFilters";
import { type FleetInventoryItemQuery } from "@/services/fyApi";

export type InventoryItemQuery = FleetInventoryItemQuery;

export const useInventoryItemFilters = (
  updateCallback?: () => Promise<void>,
) => {
  const { filter, resetFilter, isFilterSelected, filters, getQuery } =
    useFilters<FleetInventoryItemQuery>({
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
