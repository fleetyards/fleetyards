import { defineStore } from "pinia";

type MissionsStoreState = {
  // The list's two shapes: cards with their covers, or dense rows. Persisted
  // per viewer, the way the contracts board keeps its own.
  gridView: boolean;
};

export const useMissionsStore = defineStore("missions", {
  state: (): MissionsStoreState => ({
    gridView: true,
  }),
  actions: {
    toggleGridView() {
      this.gridView = !this.gridView;
    },
  },
  persist: {
    pick: ["gridView"],
  },
});
