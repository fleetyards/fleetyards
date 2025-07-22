import { type VehicleQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends VehicleQuery {}

export const useVehicleFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: [
      "searchCont",
      "manufacturerIn",
      "userUsernameIn",
      "modelSlugIn",
      "modelProductionStatusIn",
      "loanerEq",
      "wantedEq",
    ],
    updateCallback,
  });
};
