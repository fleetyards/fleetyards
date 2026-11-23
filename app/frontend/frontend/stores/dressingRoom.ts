import { defineStore } from "pinia";
import { type LocationQuery, type RouteLocationNormalized } from "vue-router";

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

// A bare address is a fresh visit, not a shared look: it is sent on to where
// the last one left off before the page draws anything.
export const lastVisitGuard = (to: RouteLocationNormalized) => {
  if (Object.keys(to.query).length) return true;

  const { lastQuery } = useDressingRoomStore();
  if (!lastQuery || !Object.keys(lastQuery).length) return true;

  return { name: to.name, query: lastQuery, replace: true };
};
