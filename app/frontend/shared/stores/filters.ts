import { defineStore } from "pinia";
import type { LocationQuery, RouteLocationNormalized } from "vue-router";
import { FILTER_EXCLUDE_KEYS } from "@/shared/composables/useFilters";

type SavedFilter = {
  query: LocationQuery;
  // A list's own view keys are no filter, so a link carrying only those still
  // arrives unfiltered.
  viewKeys: string[];
};

type FiltersState = {
  visibleFilters: string[];
  savedFilters: {
    [path: string]: SavedFilter;
  };
};

// `/ships` and `/ships/` are one list; see pageKey.
export const filterKey = (path: string) => path.replace(/(.)\/$/, "$1");

export const useFiltersStore = defineStore("filters", {
  state: (): FiltersState => ({
    visibleFilters: [],
    savedFilters: {},
  }),
  getters: {
    isVisible: (state) => {
      return (filterName: string) => state.visibleFilters.includes(filterName);
    },
  },
  actions: {
    toggle(filterName: string) {
      if (this.isVisible(filterName)) {
        this.hide(filterName);
      } else {
        this.show(filterName);
      }
    },
    show(filterName: string) {
      this.visibleFilters.push(filterName);
    },
    hide(filterName: string) {
      this.visibleFilters = this.visibleFilters.filter(
        (name) => name !== filterName,
      );
    },
    saveFilter(path: string, filter: SavedFilter) {
      this.savedFilters[filterKey(path)] = filter;
    },
    removeFilter(path: string) {
      delete this.savedFilters[filterKey(path)];
    },
  },
  persist: {
    pick: ["visibleFilters", "savedFilters"],
  },
});

/*
 * Arriving on a list without a filter of its own brings back the one it was
 * left with. A link that does carry one wins, and so does a navigation within
 * the list -- clearing the filters is one, and must stay cleared.
 */
export const restoreSavedFilter = (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
) => {
  const key = filterKey(to.path);

  if (from.matched.length && filterKey(from.path) === key) return;

  const saved = useFiltersStore().savedFilters[key];

  if (!saved) return;

  const ownFilter = Object.keys(to.query).some(
    (queryKey) =>
      !FILTER_EXCLUDE_KEYS.includes(queryKey) &&
      !saved.viewKeys.includes(queryKey),
  );

  if (ownFilter) return;

  return {
    path: to.path,
    hash: to.hash,
    query: { ...saved.query, ...to.query },
  };
};
