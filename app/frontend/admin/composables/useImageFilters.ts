import { type ImageQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export type AllowedFilters = ImageQuery;

export const useImageFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: [],
    updateCallback,
  });
};
