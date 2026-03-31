import { type ModelPaintQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useModelPaintFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<ModelPaintQuery>({
    updateCallback,
  });
};
