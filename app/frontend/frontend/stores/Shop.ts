import { defineStore } from "pinia";

interface ShopState {
  filterVisible: boolean;
}

export const useShopStore = defineStore("Shop", {
  state: (): ShopState => ({
    filterVisible: true,
  }),
  actions: {
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
  },
});
