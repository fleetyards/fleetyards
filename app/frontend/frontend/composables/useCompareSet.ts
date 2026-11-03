import { useFilters } from "@/shared/composables/useFilters";

// The slugs a compare page holds, read from and written to one query key so
// the set survives a reload and travels with a shared link.
export const useCompareSet = (key: string) => {
  const { filters, filter } = useFilters<Record<string, string[] | string>>();

  // A single occurrence parses back out of the URL as a string rather than a
  // one-element array.
  const slugs = computed<string[]>(() => [filters.value[key] || []].flat());

  const replace = (next: string[]) => {
    filter({ [key]: next });
  };

  return { slugs, replace };
};
