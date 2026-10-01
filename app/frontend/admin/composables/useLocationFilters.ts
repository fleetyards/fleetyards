import { type LocationQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useLocationFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<LocationQuery>({
    updateCallback,
  });
};
