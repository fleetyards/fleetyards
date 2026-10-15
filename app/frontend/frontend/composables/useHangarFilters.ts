import { type HangarQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

// A share link's token and a shared plaque ride in the URL of a public hangar;
// neither is a filter.
export const HANGAR_VIEW_KEYS = ["share", "plaque"];

export const useHangarFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<HangarQuery>({
    ignoreKeys: ["fleetchart"],
    viewKeys: HANGAR_VIEW_KEYS,
    updateCallback,
  });
};
