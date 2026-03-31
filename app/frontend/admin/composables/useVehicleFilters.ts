import { type VehicleQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useVehicleFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<VehicleQuery>({
    updateCallback,
  });
};
