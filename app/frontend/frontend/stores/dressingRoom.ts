import { defineStore } from "pinia";
import { type LocationQuery } from "vue-router";

type DressingRoomStoreState = {
  // The address of the last visit: what was worn and stored, the character,
  // body, pose and active outfit. Opening the page bare puts it back on.
  lastQuery: LocationQuery | null;
};

export const useDressingRoomStore = defineStore("dressingRoom", {
  state: (): DressingRoomStoreState => ({
    lastQuery: null,
  }),
  persist: {
    pick: ["lastQuery"],
  },
});
