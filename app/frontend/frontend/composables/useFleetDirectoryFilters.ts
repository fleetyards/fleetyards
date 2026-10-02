import { type FleetDirectoryQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

// vue-router hands a single value back as a string, not a one-item list, and
// the API validates `…In` filters as arrays: a clicked tag, a reload or a
// shared link would otherwise come back a 400.
const withListFilters = (query: Record<string, unknown>) =>
  Object.fromEntries(
    Object.entries(query).map(([key, value]) => [
      key,
      key.endsWith("In") && !Array.isArray(value) ? [value] : value,
    ]),
  ) as FleetDirectoryQuery;

export const useFleetDirectoryFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  const filters = useFilters<FleetDirectoryQuery>({ updateCallback });

  return {
    ...filters,
    getQuery: (formData?: FleetDirectoryQuery) =>
      withListFilters(filters.getQuery(formData)),
  };
};
