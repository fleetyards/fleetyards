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

  // The write is debounced, and dropped outright if its scope ends first, so
  // anything about to unmount sends it now.
  const flush = () => {
    filter.flush();
  };

  return { slugs, replace, flush };
};

// The last set each compare tab held, for this visit. A set lives in its own
// page's URL, so a switch to another tab and back would otherwise return to an
// empty comparison.
const remembered: Record<string, string[]> = {};

export const useRememberedCompareSet = (
  key: string,
  slugs: Ref<string[]>,
  replace: (next: string[]) => void,
) => {
  const last = remembered[key];

  if (!slugs.value.length && last?.length) {
    replace(last);
  } else {
    remembered[key] = slugs.value;
  }

  watch(slugs, (current) => {
    remembered[key] = current;
  });
};
