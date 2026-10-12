import { type BlueprintQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useBlueprintFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  const filters = useFilters<BlueprintQuery>({ updateCallback });

  const getQuery = () => filters.getQuery() as BlueprintQuery;

  return { ...filters, getQuery };
};
