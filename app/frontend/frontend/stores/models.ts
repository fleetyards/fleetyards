import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface ModelsState extends ShipListState {
  holoviewerVisible: boolean;
}

export const useModelsStore = defineStore("models", {
  state: (): ModelsState => ({
    holoviewerVisible: false,
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
  }),
  actions: {
    toggleHoloviewer() {
      this.holoviewerVisible = !this.holoviewerVisible;
    },
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
  },
  persist: {
    paths: [
      "holoviewerVisible",
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
      "perPage",
    ],
  },
});
