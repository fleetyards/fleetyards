import { type ImageQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends ImageQuery {}

export const useImageFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: [],
    updateCallback,
  });
};
