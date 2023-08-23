import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface PublicHangarState extends ShipListState {
  ships: string[];
}

export const usePublicHangarStore = defineStore("publicHangar", {
  state: (): PublicHangarState => ({
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
    ships: [],
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
    toggleFleetchart() {
      this.fleetchartVisible = !this.fleetchartVisible;
    },
    toggleColored() {
      this.fleetchartColor = !this.fleetchartColor;
    },
    updatePerPage(payload: number) {
      this.perPage = payload;
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
    paths: [
      "ships",
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
