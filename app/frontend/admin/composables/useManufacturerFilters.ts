import { type ManufacturerQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useManufacturerFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<ManufacturerQuery>({
    updateCallback,
  });
};
