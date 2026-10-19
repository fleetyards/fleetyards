import { defineStore } from "pinia";
import type { LocationQuery, RouteLocationNormalized } from "vue-router";
import { VIEW_STATE_KEYS } from "@/shared/composables/useFilters";
import { withoutTrailingSlash } from "@/shared/utils/Paths";

type SavedFilter = {
  query: LocationQuery;
  // A list's own view keys only pick what it shows, so a link carrying nothing
  // else still gets the filter back.
  viewKeys: string[];
};

type FiltersState = {
  visibleFilters: string[];
  savedFilters: {
    [path: string]: SavedFilter;
  };
};

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
      this.savedFilters[withoutTrailingSlash(path)] = filter;
    },
    removeFilter(path: string) {
      delete this.savedFilters[withoutTrailingSlash(path)];
    },
    // A search typed into a hangar is the reader's, not the next person's on
    // this browser.
    clearSavedFilters() {
      this.savedFilters = {};
    },
  },
  persist: {
    pick: ["visibleFilters", "savedFilters"],
  },
});

/*
 * Arriving on a list with nothing but view state in the URL brings back the
 * filter and sort it was left with. A link that carries anything else -- a
 * filter, a sort, a page -- shows what it was shared with, and a navigation
 * within the list is left alone: clearing the filters is one, and must stay
 * cleared.
 */
export const restoreSavedFilter = (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
) => {
  const key = withoutTrailingSlash(to.path);

  if (from.matched.length && withoutTrailingSlash(from.path) === key) return;

  const saved = useFiltersStore().savedFilters[key];

  if (!saved) return;

  // The restored query always carries a key of its own, which is what ends the
  // redirect it starts.
  const ownQuery = Object.keys(to.query).some(
    (queryKey) =>
      !VIEW_STATE_KEYS.includes(queryKey) && !saved.viewKeys.includes(queryKey),
  );

  if (ownQuery) return;

  return {
    path: to.path,
    hash: to.hash,
    query: { ...saved.query, ...to.query },
  };
};
