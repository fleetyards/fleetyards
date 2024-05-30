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
  },
  persist: {
    paths: ["holoviewerVisible", "detailsVisible"],
  },
});
