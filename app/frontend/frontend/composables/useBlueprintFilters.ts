import { type BlueprintQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

// The query params the API takes as arrays. `route.query` gives back a bare
// string when only one is set -- vue-router does no normalising -- and the
// schema rejects a string where it declared an array, so a lone material
// arrives as a 400 rather than as a filter.
const LIST_PARAMS = ["consumingCommodityIn", "craftableTypeIn"] as const;

export const useBlueprintFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  const filters = useFilters<BlueprintQuery>({ updateCallback });

  const getQuery = () => {
    const query = { ...filters.getQuery() } as Record<string, unknown>;

    LIST_PARAMS.forEach((key) => {
      const value = query[key];
      if (value === undefined || value === null || Array.isArray(value)) return;

      query[key] = [value];
    });

    return query as BlueprintQuery;
  };

  return { ...filters, getQuery };
};
