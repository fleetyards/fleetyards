import { useFilters } from "@/shared/composables/useFilters";

type RouteFilters = {
  models?: string[] | string;
};

export type CompareModelFilters = {
  models: string[];
};

export const useCompareModelFilters = (updateCallback?: () => void) => {
  const { filters, ...rest } = useFilters<RouteFilters>({
    updateCallback,
  });

  // A query carrying a single `models` occurrence parses back out of the URL as a
  // string rather than a one-element array, so a shared or reloaded one-ship
  // comparison handed every consumer a string where they iterate a list.
  const normalized = computed<CompareModelFilters>(() => ({
    ...filters.value,
    models: [filters.value.models || []].flat(),
  }));

  return { ...rest, filters: normalized };
};
