import { useSearchStore } from "@/frontend/stores/search";
import { search, type SearchResults } from "@/services/fyApi";

export type SearchScope = {
  key: string;
  labelKey: string;
  search: (q: string) => Promise<SearchResults>;
};

const CATALOGUE: SearchScope = {
  key: "catalogue",
  labelKey: "nav.catalogue.index",
  search: (q) => search({ q }),
};

export const useSearchScopes = () => {
  const store = useSearchStore();

  const scopes = computed<SearchScope[]>(() => [CATALOGUE]);

  // The saved scope may no longer be on offer: a guest, or a fleet since left.
  const current = computed(
    () =>
      scopes.value.find((scope) => scope.key === store.scope) ??
      scopes.value[0],
  );

  const select = (key: string) => {
    store.scope = key;
  };

  const step = (by: 1 | -1) => {
    const count = scopes.value.length;
    const index = scopes.value.indexOf(current.value);

    select(scopes.value[(index + by + count) % count].key);
  };

  return { scopes, current, select, step };
};
