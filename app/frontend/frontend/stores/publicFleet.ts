import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface PublicFleetState extends ShipListState {
  grouped: boolean;
}

export const usePublicFleetStore = defineStore("publicFleet", {
  state: (): PublicFleetState => ({
    detailsVisible: false,
    filterVisible: true,
    grouped: true,
  }),
  actions: {
    toggleDetails() {
      this.detailsVisible = !this.detailsVisible;
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    toggleGrouped() {
      this.grouped = !this.grouped;
    },
  },
  persist: {
    paths: ["detailsVisible", "grouped", "perPage"],
  },
});
