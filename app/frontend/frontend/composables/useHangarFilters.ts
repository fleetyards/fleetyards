import { type HangarQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useHangarFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<HangarQuery>({
    ignoreKeys: ["fleetchart"],
    // A share link's token rides in the URL of a public hangar; it is no filter.
    viewKeys: ["share"],
    updateCallback,
  });
};
