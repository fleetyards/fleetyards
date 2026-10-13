import { type HangarQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useHangarFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<HangarQuery>({
    ignoreKeys: ["fleetchart"],
    // A share link's token and a shared plaque ride in the URL of a public
    // hangar; neither is a filter.
    viewKeys: ["share", "plaque"],
    updateCallback,
  });
};
