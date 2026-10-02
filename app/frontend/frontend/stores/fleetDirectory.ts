import { defineStore } from "pinia";

type FleetDirectoryStoreState = {
  // Cards with each fleet's logo, or dense rows. Persisted per viewer, the way
  // the missions and contracts lists keep theirs.
  gridView: boolean;
};

export const useFleetDirectoryStore = defineStore("fleetDirectory", {
  state: (): FleetDirectoryStoreState => ({
    gridView: true,
  }),
  persist: {
    pick: ["gridView"],
  },
});
