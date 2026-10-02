import { type LocationQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

// `route.query` gives back a bare string when only one value is set, and the
// schema rejects a string where it declared an array.
const LIST_PARAMS = ["kindIn", "nameIn"] as const;

export const useLocationFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  const filters = useFilters<LocationQuery>({ updateCallback });

  const getQuery = () => {
    const query = { ...filters.getQuery() } as Record<string, unknown>;

    LIST_PARAMS.forEach((key) => {
      const value = query[key];
      if (value === undefined || value === null || Array.isArray(value)) return;

      query[key] = [value];
    });

    return query as LocationQuery;
  };

  return { ...filters, getQuery };
};
