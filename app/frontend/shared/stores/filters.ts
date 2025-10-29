import { defineStore } from "pinia";

type FilterValue = {
  [key: string]: string | number | boolean | null | string[] | number[];
};

type FiltersState = {
  visibleFilters: string[];
  filters: {
    [key: string]: FilterValue;
  };
};

export const useFiltersStore = defineStore("filters", {
  state: (): FiltersState => ({
    visibleFilters: [],
    filters: {},
  }),
  getters: {
    isVisible: (state) => {
      return (filterName: string) => state.visibleFilters.includes(filterName);
    },
    getFilters: (state) => {
      return (filterName: string) => state.filters[filterName] || {};
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
    setFilter(filterName: string, filterValue: FilterValue) {
      this.filters[filterName] = filterValue;
    },
    removeFilter(filterName: string) {
      delete this.filters[filterName];
    },
  },
  persist: true,
});
