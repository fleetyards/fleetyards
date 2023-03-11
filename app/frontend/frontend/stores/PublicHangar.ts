import { defineStore } from "pinia";
import type { ShipListState } from "@/@types/stores/ShipList";

export const usePublicHangarStore = defineStore("PublicHangar", {
  state: (): ShipListState => ({
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
