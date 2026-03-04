import { type ImageQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useImageFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<ImageQuery>({
    updateCallback,
  });
};
