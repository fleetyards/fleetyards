import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface HangarState extends ShipListState {
  ships: string[];
  preview: boolean;
  starterGuideVisible: boolean;
  gridView: boolean;
  money: boolean;
  extensionReady: boolean;
}

export const useHangarStore = defineStore("hangar", {
  state: (): HangarState => ({
    detailsVisible: false,
    filterVisible: true,
    money: true,
    ships: [],
    preview: true,
    starterGuideVisible: false,
    gridView: true,
    extensionReady: false,
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
    toggleMoney() {
      this.money = !this.money;
    },
    hidePreview() {
      this.preview = false;
    },
    toggleGridView() {
      this.gridView = !this.gridView;
    },
    save(payload: string[]) {
      this.ships = payload;

      if (payload.length > 0 && this.starterGuideVisible) {
        this.starterGuideVisible = false;
      }
    },
    add(payload: string) {
      this.ships.push(payload);

      if (this.starterGuideVisible) {
        this.starterGuideVisible = false;
      }
    },
    remove(payload: string) {
      this.ships.splice(this.ships.indexOf(payload), 1);
    },
    enableStarterGuide() {
      this.starterGuideVisible = true;
    },
  },
  persist: {
    paths: [
      "ships",
      "detailsVisible",
      "preview",
      "money",
      "starterGuideVisible",
      "gridView",
    ],
  },
});
