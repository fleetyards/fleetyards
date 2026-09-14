import { defineStore } from "pinia";

type ContractsStoreState = {
  // The board's two shapes: cards with their covers, or dense rows. Persisted
  // per viewer, the way the ships and hangar lists keep theirs.
  gridView: boolean;
};

export const useContractsStore = defineStore("contracts", {
  state: (): ContractsStoreState => ({
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
