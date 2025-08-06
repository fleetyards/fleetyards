import { type ManufacturerQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export type AllowedFilters = ManufacturerQuery;

export const useManufacturerFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: ["nameCont", "withModels", "logoBlank"],
    updateCallback,
  });
};
