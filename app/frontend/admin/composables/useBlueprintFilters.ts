import { type BlueprintQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useBlueprintFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<BlueprintQuery>({
    updateCallback,
  });
};
