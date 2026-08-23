import { type EquipmentQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useEquipmentFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<EquipmentQuery>({
    updateCallback,
  });
};
