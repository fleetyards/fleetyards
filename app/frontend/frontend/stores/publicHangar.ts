import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface PublicHangarState extends ShipListState {
  ships: string[];
}

export const usePublicHangarStore = defineStore("publicHangar", {
  state: (): PublicHangarState => ({
    detailsVisible: false,
    filterVisible: true,
    ships: [],
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
    save(payload: string[]) {
      this.ships = payload;
    },
    add(payload: string) {
      this.ships.push(payload);
    },
    remove(payload: string) {
      this.ships.splice(this.ships.indexOf(payload), 1);
    },
  },
  persist: {
    pick: ["ships", "detailsVisible"],
  },
});
