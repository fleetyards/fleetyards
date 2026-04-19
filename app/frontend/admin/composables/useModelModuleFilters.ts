import { type ModelModuleQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useModelModuleFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<ModelModuleQuery>({
    updateCallback,
  });
};
