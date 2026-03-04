import { type ModelQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useModelFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<ModelQuery>({
    updateCallback,
  });
};
