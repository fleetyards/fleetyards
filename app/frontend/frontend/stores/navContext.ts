import { defineStore } from "pinia";

type NavContextState = {
  // The fleet the navigation is showing, or null for the reader's own hangar.
  fleetSlug: string | null;
};

/*
 * Kept rather than read off the route: the account's own pages belong to no
 * fleet, and opening one of them must not switch the reader out of the fleet
 * they came from. Persisted, so a reload of such a page does not either.
 */
export const useNavContextStore = defineStore("navContext", {
  state: (): NavContextState => ({
    fleetSlug: null,
  }),
  persist: {
    pick: ["fleetSlug"],
  },
});
