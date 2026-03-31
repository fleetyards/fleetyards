import { type ModelQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends ModelQuery {
  fleetchart?: boolean;
}

export const useModelFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<AllowedFilters>({
    ignoreKeys: ["fleetchart"],
    updateCallback,
  });
};
