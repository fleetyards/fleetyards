import { defineStore } from "pinia";
import type { ShipListState } from "@/@types/stores/ShipList";

interface ModelsState extends ShipListState {
  holoviewerVisible: boolean;
}

export const useModelsStore = defineStore("Models", {
  state: (): ModelsState => ({
    detailsVisible: false,
    filterVisible: false,
    fleetchartVisible: false,
    fleetchartZoomData: undefined,
    fleetchartViewpoint: "side",
    fleetchartLabels: false,
    fleetchartScreenHeight: "1x",
    fleetchartMode: "panzoom",
    fleetchartScale: 1,
    perPage: 30,
    holoviewerVisible: false,
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
    toggleHoloviewer() {
      this.holoviewerVisible = !this.holoviewerVisible;
    },
    enableHoloviewer() {
      this.holoviewerVisible = true;
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
      "holoviewerVisible",
      "perPage",
    ],
  },
});
