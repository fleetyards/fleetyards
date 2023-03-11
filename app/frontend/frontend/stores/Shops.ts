import { defineStore } from "pinia";

interface ShopsState {
  filterVisible: boolean;
}

export const useShopsStore = defineStore("Shops", {
  state: (): ShopsState => ({
    filterVisible: true,
  }),
  actions: {
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
  },
});
