import { defineStore } from "pinia";

interface VehicleViewState {
  // The vehicles whose header shows the 3D model rather than the picture.
  // Per vehicle, and apart from the ship page's switch: a captain may keep one
  // ship in 3D and the next on its own picture.
  holoVehicleIds: string[];
}

export const useVehicleViewStore = defineStore("vehicleView", {
  state: (): VehicleViewState => ({
    holoVehicleIds: [],
  }),
  getters: {
    holoVisible(state) {
      return (vehicleId: string) => state.holoVehicleIds.includes(vehicleId);
    },
  },
  actions: {
    toggleHolo(vehicleId: string) {
      this.holoVehicleIds = this.holoVehicleIds.includes(vehicleId)
        ? this.holoVehicleIds.filter((id) => id !== vehicleId)
        : [...this.holoVehicleIds, vehicleId];
    },
  },
  persist: {
    pick: ["holoVehicleIds"],
  },
});
