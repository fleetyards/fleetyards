import type { ShipListState } from "@/@types/stores/ShipList";
import { defineStore } from "pinia";

interface PublicFleetState extends ShipListState {
  grouped: boolean;
}

export const usePublicFleetStore = defineStore("PublicFleet", {
  state: (): PublicFleetState => ({
    detailsVisible: false,
    filterVisible: true,
    fleetchartVisible: false,
    fleetchartZoomData: undefined,
    fleetchartViewpoint: "side",
    fleetchartLabels: false,
    fleetchartScreenHeight: "1x",
    fleetchartMode: "panzoom",
    fleetchartScale: 1,
    perPage: 30,
    grouped: true,
  }),
  actions: {
    toggleDetails() {
      this.detailsVisible = !this.detailsVisible;
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    toggleFleetchart() {
      this.fleetchartVisible = !this.fleetchartVisible;
    },
    updatePerPage(payload: number) {
      this.perPage = payload;
    },
    toggleGrouped() {
      this.grouped = !this.grouped;
    },
  },
  persist: {
    paths: [
      "fleetchartVisible",
      "fleetchartScale",
      "fleetchartZoomData",
      "fleetchartViewpoint",
      "fleetchartLabels",
      "fleetchartScreenHeight",
      "fleetchartMode",
    ],
  },
});
