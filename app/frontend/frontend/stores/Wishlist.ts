import { defineStore } from "pinia";

interface WishlistState {
  ships: string[];
  gridView: boolean;
  detailsVisible: boolean;
  filterVisible: boolean;
  perPage: number;
}

export const useWishlistStore = defineStore("Wishlist", {
  state: (): WishlistState => ({
    ships: [],
    detailsVisible: false,
    filterVisible: true,
    perPage: 30,
    gridView: true,
  }),
  getters: {
    empty(state) {
      return state.ships.length === 0;
    },
  },
  actions: {
    toggleDetails() {
      this.detailsVisible = !this.detailsVisible;
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    updatePerPage(payload: number) {
      this.perPage = payload;
    },
    toggleGridView() {
      this.gridView = !this.gridView;
    },
    save(payload) {
      this.ships = payload;
    },
    add(payload) {
      this.ships.push(payload);
    },
    remove(payload) {
      this.ships.splice(this.ships.indexOf(payload), 1);
    },
  },
  persist: {
    paths: ["ships", "detailsVisible", "perPage", "gridView"],
  },
});
