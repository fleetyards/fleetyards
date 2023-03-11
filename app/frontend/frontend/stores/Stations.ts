import { defineStore } from "pinia";

interface StationsState {
  filterVisible: boolean;
}

export const useStationsStore = defineStore("Stations", {
  state: (): StationsState => ({
    filterVisible: true,
  }),
  actions: {
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
  },
});
