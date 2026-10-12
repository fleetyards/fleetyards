import { type LocationQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useLocationFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  const filters = useFilters<LocationQuery>({ updateCallback });

  const getQuery = () => filters.getQuery() as LocationQuery;

  return { ...filters, getQuery };
};
