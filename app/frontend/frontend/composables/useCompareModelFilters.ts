import { useFilters } from "@/shared/composables/useFilters";

type AllowedFilters = {
  models?: string[];
};

export const useCompareModelFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: ["models"],
    updateCallback,
  });
};
