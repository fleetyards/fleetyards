import { type HangarQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useHangarFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<HangarQuery>({
    ignoreKeys: ["fleetchart"],
    updateCallback,
  });
};
