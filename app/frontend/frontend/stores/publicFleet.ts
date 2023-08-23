import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface PublicFleetState extends ShipListState {
  grouped: boolean;
}

export const usePublicFleetStore = defineStore("publicFleet", {
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
    fleetchartColor: false,
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
    toggleColored() {
      this.fleetchartColor = !this.fleetchartColor;
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
      "detailsVisible",
      "fleetchartVisible",
      "fleetchartScale",
      "fleetchartZoomData",
      "fleetchartViewpoint",
      "fleetchartLabels",
      "fleetchartScreenHeight",
      "fleetchartMode",
      "fleetchartScale",
      "fleetchartColor",
      "grouped",
      "perPage",
    ],
  },
});
